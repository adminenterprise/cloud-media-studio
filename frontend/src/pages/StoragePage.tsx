export default function StoragePage() {
  const tiers = [
    { name: 'S3 Standard', price: '$0.025', desc: 'Đơn giá / GB / tháng', note: 'Truy xuất tức thì', border: 'border-t-indigo-600' },
    { name: 'S3 Standard-IA', price: '$0.0125', desc: 'Tiết kiệm 50%', note: 'Truy cập không thường xuyên', border: 'border-t-cyan-500' },
    { name: 'S3 Glacier Flexible', price: '$0.0040', desc: 'Tiết kiệm 84%', note: 'Kho lưu trữ lạnh (FinOps)', border: 'border-t-emerald-500', highlight: true },
    { name: 'Glacier Deep Archive', price: '$0.00099', desc: 'Tiết kiệm 96%', note: 'Lưu trữ hồ sơ vĩnh viễn', border: 'border-t-slate-500' },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-extrabold tracking-tight text-slate-900 dark:text-white">Quản Trị Lưu Trữ & FinOps (S3 Glacier Lifecycle)</h1>
        <p className="text-sm text-slate-500 mt-1">Chính sách vòng đời tự động chuyển media cũ sang S3 Glacier sau 30 ngày giúp giảm 84% chi phí lưu trữ</p>
      </div>

      {/* Tiers Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {tiers.map((t, idx) => (
          <div key={idx} className={`p-5 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm border-t-4 ${t.border} ${t.highlight ? 'bg-emerald-50/50 dark:bg-emerald-950/20' : ''}`}>
            <div className="text-xs font-bold text-slate-500 uppercase tracking-wider">{t.name}</div>
            <div className={`text-2xl font-extrabold my-1 ${t.highlight ? 'text-emerald-600' : 'text-slate-900 dark:text-white'}`}>{t.price}</div>
            <div className="text-xs font-semibold text-slate-600 dark:text-slate-400">{t.desc}</div>
            <div className="text-[11px] text-slate-400 mt-2 pt-2 border-t border-slate-100 dark:border-slate-800">{t.note}</div>
          </div>
        ))}
      </div>

      {/* S3 Lifecycle Roadmap */}
      <div className="p-6 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm space-y-4">
        <h2 className="font-bold text-slate-900 dark:text-white">Lộ Trình Chính Sách Vòng Đời Tự Động (S3 Lifecycle Timeline)</h2>
        <div className="flex flex-col md:flex-row items-center gap-4 pt-2">
          <div className="flex-1 w-full p-4 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700">
            <span className="text-[10px] font-extrabold text-indigo-600 dark:text-indigo-400 uppercase tracking-wider">NGÀY 0</span>
            <div className="font-bold text-slate-900 dark:text-white mt-1">Upload S3 Standard</div>
            <div className="text-xs text-slate-500 mt-0.5">Truy xuất tức thì qua CloudFront CDN</div>
          </div>

          <div className="text-xl text-indigo-600 hidden md:block">➔</div>

          <div className="flex-1 w-full p-4 rounded-xl bg-emerald-50 dark:bg-emerald-950/60 border border-emerald-300 dark:border-emerald-800 text-emerald-900 dark:text-emerald-100">
            <span className="text-[10px] font-extrabold text-emerald-600 dark:text-emerald-400 uppercase tracking-wider">NGÀY 30 (FINOPS)</span>
            <div className="font-bold mt-1">Chuyển Sang S3 Glacier</div>
            <div className="text-xs opacity-80 mt-0.5">Giảm 84% chi phí lưu trữ cho tệp cũ</div>
          </div>

          <div className="text-xl text-indigo-600 hidden md:block">➔</div>

          <div className="flex-1 w-full p-4 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700">
            <span className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">NGÀY 90+</span>
            <div className="font-bold text-slate-900 dark:text-white mt-1">Deep Archive / Expire</div>
            <div className="text-xs text-slate-500 mt-0.5">Lưu trữ vĩnh viễn hồ sơ chứng từ</div>
          </div>
        </div>
      </div>
    </div>
  );
}

