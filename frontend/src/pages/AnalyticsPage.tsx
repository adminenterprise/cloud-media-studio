export default function AnalyticsPage() {
  const formats = [
    { label: 'WebP (Đã nén tối ưu)', pct: 48, color: 'bg-indigo-600' },
    { label: 'Video MP4', pct: 26, color: 'bg-purple-600' },
    { label: 'PNG Raster/Vector', pct: 18, color: 'bg-cyan-500' },
    { label: 'JPG / JPEG', pct: 8, color: 'bg-amber-500' },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-extrabold tracking-tight text-slate-900 dark:text-white">Thống Kê Hiệu Năng & Băng Thông</h1>
        <p className="text-sm text-slate-500 mt-1">Phân tích tần suất truy cập qua CloudFront CDN và tỷ lệ nén dung lượng Serverless</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Upload volume trend */}
        <div className="lg:col-span-2 p-6 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="font-bold text-slate-900 dark:text-white">Tần Suất Tải Lên 6 Tháng Gần Nhất</h2>
            <span className="text-xs text-slate-400">Đơn vị: Tệp</span>
          </div>

          <div className="h-56 flex items-end gap-3 pt-6 pb-2 border-b border-slate-100 dark:border-slate-800">
            {[
              { m: 'Th 6', h: '35%' },
              { m: 'Th 7', h: '48%' },
              { m: 'Th 8', h: '62%' },
              { m: 'Th 9', h: '78%' },
              { m: 'Th 10', h: '90%' },
              { m: 'Th 11', h: '100%', active: true },
            ].map((col, idx) => (
              <div key={idx} className="flex-1 flex flex-col items-center h-full justify-end gap-2">
                <div 
                  className={`w-full max-w-[40px] rounded-t-md transition-all ${col.active ? 'bg-indigo-600' : 'bg-indigo-200 dark:bg-indigo-950'}`}
                  style={{ height: col.h }}
                ></div>
                <span className="text-[11px] font-semibold text-slate-500">{col.m}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Format Breakdown */}
        <div className="p-6 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm space-y-4">
          <h2 className="font-bold text-slate-900 dark:text-white">Phân Bổ Định Dạng Media</h2>
          
          <div className="space-y-3 pt-2">
            {formats.map((f, i) => (
              <div key={i} className="space-y-1">
                <div className="flex justify-between text-xs font-semibold">
                  <span className="text-slate-600 dark:text-slate-400">{f.label}</span>
                  <span className="font-bold text-slate-900 dark:text-white">{f.pct}%</span>
                </div>
                <div className="h-2 rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden">
                  <div className={`h-full ${f.color}`} style={{ width: `${f.pct}%` }}></div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

