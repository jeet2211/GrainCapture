import cv2
import numpy as np
import argparse
from pathlib import Path

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--video', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--bg-start', type=float, default=0.5)
    ap.add_argument('--bg-end', type=float, default=2.5)
    ap.add_argument('--chroma-th', type=float, default=14.0)
    args = ap.parse_args()

    video = Path(args.video)
    out = Path(args.out)
    (out / 'masks').mkdir(parents=True, exist_ok=True)
    (out / 'crops').mkdir(parents=True, exist_ok=True)

    cap = cv2.VideoCapture(str(video))
    if not cap.isOpened():
        raise RuntimeError(f'Cannot open {video}')
    fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    frames=[]
    while True:
        ok, fr = cap.read()
        if not ok: break
        frames.append(fr)
    cap.release()

    s=max(0,int(args.bg_start*fps)); e=min(len(frames),max(s+3,int(args.bg_end*fps)))
    bg=np.median(np.stack(frames[s:e]),axis=0).astype(np.uint8)
    bg_lab=cv2.cvtColor(bg,cv2.COLOR_BGR2LAB).astype(np.float32)
    hsv=cv2.cvtColor(bg,cv2.COLOR_BGR2HSV)
    sheet=((hsv[:,:,0]>95)&(hsv[:,:,0]<115)&(hsv[:,:,1]>150)).astype(np.uint8)*255
    sheet=cv2.erode(sheet,cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(31,31)))
    sheet[int(h*0.92):,:]=0
    rm=sheet>0

    fourcc=cv2.VideoWriter_fourcc(*'mp4v')
    preview=cv2.VideoWriter(str(out/'segmentation_preview_v4.mp4'),fourcc,fps,(960,600))
    crop_id=0
    for fi,frame in enumerate(frames):
        lab=cv2.cvtColor(frame,cv2.COLOR_BGR2LAB).astype(np.float32)
        diff=lab-bg_lab
        off=np.median(diff[rm][:,1:3],axis=0)
        adj=lab[:,:,1:3]-off
        dab=np.sqrt(np.sum((adj-bg_lab[:,:,1:3])**2,axis=2))
        raw=((dab>args.chroma_th)&rm).astype(np.uint8)*255
        raw=cv2.morphologyEx(raw,cv2.MORPH_OPEN,np.ones((3,3),np.uint8))
        raw=cv2.morphologyEx(raw,cv2.MORPH_CLOSE,np.ones((5,5),np.uint8))
        clean=np.zeros_like(raw)
        if int((raw>0).sum()) < 15000:
            num,labels,stats,_=cv2.connectedComponentsWithStats(raw)
            for j in range(1,num):
                x,y,cw,ch,area=map(int,stats[j])
                if not (80<=area<=6000): continue
                if not (5<=cw<=100 and 8<=ch<=200): continue
                if x<100 or x+cw>w-100 or y<20: continue
                clean[labels==j]=255
        overlay=frame.copy()
        contours,_=cv2.findContours(clean,cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_SIMPLE)
        for c in contours:
            x,y,cw,ch=cv2.boundingRect(c); area=cv2.contourArea(c)
            cv2.drawContours(overlay,[c],-1,(0,255,0),3)
            cv2.rectangle(overlay,(x,y),(x+cw,y+ch),(0,255,0),2)
            cv2.putText(overlay,f'grain {area:.0f}px',(x,max(25,y-8)),cv2.FONT_HERSHEY_SIMPLEX,0.7,(0,255,0),2)
            pad=20; x0=max(0,x-pad); y0=max(0,y-pad); x1=min(w,x+cw+pad); y1=min(h,y+ch+pad)
            crop=frame[y0:y1,x0:x1]; cmask=clean[y0:y1,x0:x1]
            crop_id+=1
            cv2.imwrite(str(out/'crops'/f'candidate_{crop_id:04d}_f{fi:04d}.png'),crop)
            cv2.imwrite(str(out/'masks'/f'candidate_{crop_id:04d}_f{fi:04d}_mask.png'),cmask)
        small=cv2.resize(overlay,(960,600),interpolation=cv2.INTER_AREA)
        cv2.putText(small,f'frame={fi} actual_fps={fps:.2f} detections={len(contours)}',(15,30),cv2.FONT_HERSHEY_SIMPLEX,0.7,(0,255,255),2)
        preview.write(small)
    preview.release()
    cv2.imwrite(str(out/'background_model.jpg'),bg)
    print(f'Actual source FPS: {fps:.3f}')
    print(f'Frames: {len(frames)}')
    print(f'Saved candidate crops: {crop_id}')
    print(out/'segmentation_preview_v4.mp4')

if __name__=='__main__': main()
