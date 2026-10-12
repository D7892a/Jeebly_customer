/* Client-side upload optimization. White-background removal is intentionally limited to near-white connected edge pixels. */
window.mansPrepareImage = async function(file, kind='portrait') {
  if (!file || !file.type.startsWith('image/')) throw Error('اختر صورة صالحة');
  if (file.size > 40 * 1024 * 1024) throw Error('الصورة أكبر من 40MB؛ اختر نسخة أصغر');
  const bitmap = await createImageBitmap(file).catch(()=>{throw Error('تعذر قراءة الصورة؛ استخدم JPG أو PNG أو WebP')});
  try {
    const max = kind==='logo'?900:1200;
    const scale=Math.min(1,max/Math.max(bitmap.width,bitmap.height));
    const w=Math.max(1,Math.round(bitmap.width*scale)),h=Math.max(1,Math.round(bitmap.height*scale));
    const canvas=document.createElement('canvas');canvas.width=w;canvas.height=h;
    const ctx=canvas.getContext('2d',{willReadFrequently:kind==='logo'});
    ctx.imageSmoothingEnabled=true;ctx.imageSmoothingQuality='high';ctx.drawImage(bitmap,0,0,w,h);
    if(kind==='logo') {
      const img=ctx.getImageData(0,0,w,h),p=img.data;
      // Flood-fill only near-white pixels connected to the image border;
      // this avoids deleting white elements enclosed inside the team emblem.
      const seen=new Uint8Array(w*h),stack=[];
      function nearWhite(i){const k=i*4;return p[k]>239&&p[k+1]>239&&p[k+2]>239&&p[k+3]>0}
      function add(i){if(!seen[i]&&nearWhite(i)){seen[i]=1;stack.push(i)}}
      for(let x=0;x<w;x++){add(x);add((h-1)*w+x)}
      for(let y=0;y<h;y++){add(y*w);add(y*w+w-1)}
      while(stack.length){const i=stack.pop(),x=i%w,y=(i/w)|0,k=i*4;
        const white=Math.min(p[k],p[k+1],p[k+2]);
        p[k+3]=white>=250?0:Math.round(p[k+3]*(250-white)/11);
        if(x>0)add(i-1);if(x<w-1)add(i+1);if(y>0)add(i-w);if(y<h-1)add(i+w);
      }
      ctx.putImageData(img,0,0);
    }
    async function encode(quality){return new Promise((resolve,reject)=>canvas.toBlob(b=>b?resolve(b):reject(Error('فشل ضغط الصورة')),'image/webp',quality))}
    let blob=await encode(.86);
    if(blob.size>1900000)blob=await encode(.65);
    if(blob.size>2097152)throw Error('تعذر ضغط الصورة إلى الحجم المسموح');
    return new File([blob],(kind==='logo'?'logo':'portrait')+'.webp',{type:'image/webp'});
  } finally {bitmap.close?.()}
};
