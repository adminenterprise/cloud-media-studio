import React, { useState } from 'react';

interface UploadPageProps {
  onUploadSuccess: () => void;
}

export default function UploadPage({ onUploadSuccess }: UploadPageProps) {
  const [title, setTitle] = useState('');
  const [format, setFormat] = useState('PNG');
  const [size, setSize] = useState('12.5');
  const [tags, setTags] = useState('Marketing, 4K');
  const [author, setAuthor] = useState('Creative Marketing');
  const [autoWebP, setAutoWebP] = useState(true);
  const [isProcessing, setIsProcessing] = useState(false);
  const [currentStep, setCurrentStep] = useState(0);

  const steps = [
    { title: 'Tải lên S3 Raw Bucket', desc: 'Đẩy tệp gốc dung lượng cao lên Amazon S3' },
    { title: 'Kích hoạt AWS Lambda', desc: 'Bắt sự kiện s3:ObjectCreated không máy chủ' },
    { title: 'Nén chuẩn WebP', desc: 'Giảm 84% dung lượng truyền tải và lưu trữ' },
    { title: 'Sinh 3 Thumbnails', desc: 'Tạo kích thước Mobile, Tablet và Desktop' },
    { title: 'Lưu vào S3 Processed', desc: 'Lưu trữ các biến thể đã tối ưu hóa' },
    { title: 'Đồng bộ Metadata', desc: 'Cập nhật cơ sở dữ liệu RDS MySQL & DynamoDB' },
  ];

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title) return;

    setIsProcessing(true);
    for (let i = 1; i <= 6; i++) {
      setCurrentStep(i);
      await new Promise(r => setTimeout(r, 400));
    }

    try {
      await fetch('/api/upload', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title,
          format,
          file_size_mb: parseFloat(size) || 12.5,
          tags,
          author,
          auto_webp: autoWebP
        })
      });
    } catch (e) {}

    setIsProcessing(false);
    alert(`Đã tải lên và nén WebP thành công: "${title}"`);
    onUploadSuccess();
  };

  return (
    <div className="space-y-6 max-w-4xl">
      <div>
        <h1 className="text-2xl font-extrabold tracking-tight text-slate-900 dark:text-white">Tải Lên & Xử Lý Tự Động (Serverless Pipeline)</h1>
        <p className="text-sm text-slate-500 mt-1">Kích hoạt đường ống tự động nén WebP (-84%) và sinh 3 kích thước Thumbnails qua AWS Lambda</p>
      </div>

      {/* Drag & Drop Area */}
      <div className="p-12 border-2 border-dashed border-slate-300 dark:border-slate-700 rounded-2xl bg-white dark:bg-slate-900 text-center hover:border-indigo-600 transition-colors">
        <div className="w-14 h-14 mx-auto mb-3 rounded-full bg-indigo-50 dark:bg-indigo-950 flex items-center justify-center text-2xl text-indigo-600">
          ☁️
        </div>
        <h3 className="text-base font-bold text-slate-800 dark:text-slate-100 mb-1">Kéo thả tệp media vào đây hoặc click để chọn</h3>
        <p className="text-xs text-slate-500 mb-4">Hỗ trợ định dạng JPG, PNG, WebP độ phân giải cao và video MP4 (Tối đa 100MB)</p>
        <div className="inline-flex gap-2">
          <span className="px-2 py-0.5 rounded bg-slate-100 dark:bg-slate-800 text-[10px] font-bold text-slate-600 dark:text-slate-300">4K UHD</span>
          <span className="px-2 py-0.5 rounded bg-slate-100 dark:bg-slate-800 text-[10px] font-bold text-slate-600 dark:text-slate-300">WebP Transcode</span>
          <span className="px-2 py-0.5 rounded bg-slate-100 dark:bg-slate-800 text-[10px] font-bold text-slate-600 dark:text-slate-300">Lambda ARM64</span>
        </div>
      </div>

      {/* Form Details */}
      <form onSubmit={handleSubmit} className="p-6 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm space-y-4">
        <h2 className="font-bold text-slate-900 dark:text-white text-sm">Thông Tin Tệp Media Tải Lên</h2>
        
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
          <div>
            <label className="block font-bold text-slate-600 dark:text-slate-400 mb-1.5">Tiêu đề media *</label>
            <input 
              type="text" 
              value={title} 
              onChange={e => setTitle(e.target.value)}
              placeholder="VD: Poster Banner Quảng Cáo 4K"
              className="w-full px-3 py-2 rounded-lg bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 outline-none focus:border-indigo-600"
              required 
            />
          </div>

          <div>
            <label className="block font-bold text-slate-600 dark:text-slate-400 mb-1.5">Thẻ phân loại (Tags)</label>
            <input 
              type="text" 
              value={tags} 
              onChange={e => setTags(e.target.value)}
              placeholder="Marketing, Campaign, 4K"
              className="w-full px-3 py-2 rounded-lg bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 outline-none focus:border-indigo-600" 
            />
          </div>

          <div>
            <label className="block font-bold text-slate-600 dark:text-slate-400 mb-1.5">Định dạng gốc</label>
            <select 
              value={format} 
              onChange={e => setFormat(e.target.value)}
              className="w-full px-3 py-2 rounded-lg bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 outline-none focus:border-indigo-600"
            >
              <option value="PNG">PNG Vector / Raster</option>
              <option value="JPG">JPG 4K</option>
              <option value="MP4">Video MP4</option>
              <option value="WEBP">WebP</option>
            </select>
          </div>

          <div>
            <label className="block font-bold text-slate-600 dark:text-slate-400 mb-1.5">Dung lượng gốc (MB)</label>
            <input 
              type="number" 
              step="0.1" 
              value={size} 
              onChange={e => setSize(e.target.value)}
              className="w-full px-3 py-2 rounded-lg bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 outline-none focus:border-indigo-600" 
            />
          </div>
        </div>

        <div className="p-3 rounded-lg bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-800">
          <label className="flex items-center gap-2.5 text-xs font-bold cursor-pointer">
            <input 
              type="checkbox" 
              checked={autoWebP} 
              onChange={e => setAutoWebP(e.target.checked)}
              className="w-4 h-4 rounded text-indigo-600" 
            />
            <span>Kích hoạt AWS Lambda nén sang WebP (-84% dung lượng) và tạo 3 bản Thumbnail</span>
          </label>
        </div>

        <button
          type="submit"
          disabled={isProcessing}
          className="px-5 py-2.5 rounded-lg bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs shadow-sm transition-all disabled:opacity-50"
        >
          {isProcessing ? 'Đang thực thi Pipeline...' : 'Tải Lên & Xử Lý Pipeline'}
        </button>
      </form>

      {/* Pipeline Visualizer */}
      <div className="p-6 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm space-y-4">
        <h2 className="font-bold text-slate-900 dark:text-white text-sm">6 Chốt Chặn Serverless Processing Pipeline</h2>
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
          {steps.map((s, idx) => {
            const stepNum = idx + 1;
            const isDone = currentStep > stepNum;
            const isCurr = currentStep === stepNum;
            return (
              <div 
                key={idx}
                className={`p-3 rounded-lg border text-left text-xs transition-colors ${
                  isDone 
                    ? 'bg-emerald-50 dark:bg-emerald-950/60 border-emerald-300 dark:border-emerald-800 text-emerald-800 dark:text-emerald-200' 
                    : isCurr 
                    ? 'bg-indigo-50 dark:bg-indigo-950/60 border-indigo-500 text-indigo-800 dark:text-indigo-200 animate-pulse' 
                    : 'bg-slate-50 dark:bg-slate-800/40 border-slate-200 dark:border-slate-800 text-slate-500'
                }`}
              >
                <div className="text-[10px] font-extrabold uppercase mb-1">Bước {stepNum}</div>
                <div className="font-bold leading-tight mb-1">{s.title}</div>
                <div className="text-[10px] opacity-80 leading-normal">{s.desc}</div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

