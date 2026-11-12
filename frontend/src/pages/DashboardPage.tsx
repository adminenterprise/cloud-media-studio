import { PageId } from '../App';
import { INITIAL_MEDIA_ITEMS } from '../services/mockData';

interface DashboardPageProps {
  onNavigate: (page: PageId) => void;
}

export default function DashboardPage({ onNavigate }: DashboardPageProps) {
  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold tracking-tight text-slate-900 dark:text-white">Bảng Điều Khiển Tổng Quan</h1>
          <p className="text-sm text-slate-500 mt-1">Giám sát tài nguyên đa phương tiện, xử lý Serverless và tối ưu hóa chi phí FinOps</p>
        </div>
        <button
          onClick={() => onNavigate('upload-media')}
          className="self-start sm:self-auto px-4 py-2 rounded-lg bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold transition-all shadow-sm"
        >
          + Thêm Tài Nguyên Media
        </button>
      </div>

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="p-5 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex items-center justify-between text-slate-500 text-xs font-bold uppercase tracking-wider mb-2">
            <span>Tổng Tài Nguyên</span>
            <span className="text-lg">📁</span>
          </div>
          <div className="text-3xl font-extrabold text-slate-900 dark:text-white">{INITIAL_MEDIA_ITEMS.length}</div>
          <div className="text-xs text-emerald-600 font-semibold mt-1">↑ +14.2% so với tháng trước</div>
        </div>

        <div className="p-5 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex items-center justify-between text-slate-500 text-xs font-bold uppercase tracking-wider mb-2">
            <span>Dung Lượng Sử Dụng</span>
            <span className="text-lg">💾</span>
          </div>
          <div className="text-3xl font-extrabold text-slate-900 dark:text-white">106.4 MB</div>
          <div className="text-xs text-slate-500 mt-1">Hạn mức Free Tier: 100 GB</div>
        </div>

        <div className="p-5 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex items-center justify-between text-slate-500 text-xs font-bold uppercase tracking-wider mb-2">
            <span>FinOps S3 Glacier</span>
            <span className="text-lg">❄️</span>
          </div>
          <div className="text-3xl font-extrabold text-emerald-600">84.0%</div>
          <div className="text-xs text-slate-500 mt-1">Tiết kiệm $87.40 / năm</div>
        </div>

        <div className="p-5 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex items-center justify-between text-slate-500 text-xs font-bold uppercase tracking-wider mb-2">
            <span>AWS Budgets ($200)</span>
            <span className="text-lg">💳</span>
          </div>
          <div className="text-3xl font-extrabold text-indigo-600 dark:text-indigo-400">$9.82</div>
          <div className="text-xs text-slate-500 mt-1">Còn lại: $190.18 USD</div>
        </div>
      </div>

      {/* Storage Breakdown */}
      <div className="p-6 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="font-bold text-slate-900 dark:text-white">Phân Bổ Tầng Lưu Trữ (S3 Storage Breakdown)</h2>
            <p className="text-xs text-slate-500 mt-0.5">Tự động tối ưu chi phí theo chính sách S3 Lifecycle sau 30 ngày</p>
          </div>
          <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 border border-indigo-200 dark:border-indigo-800">
            Multi-Tier Active
          </span>
        </div>

        {/* Multi-segment bar */}
        <div className="h-3 rounded-full bg-slate-100 dark:bg-slate-800 flex overflow-hidden">
          <div className="h-full bg-indigo-600" style={{ width: '58%' }} title="S3 Standard (58%)"></div>
          <div className="h-full bg-cyan-500" style={{ width: '22%' }} title="Processed WebP (22%)"></div>
          <div className="h-full bg-emerald-500" style={{ width: '20%' }} title="S3 Glacier (20%)"></div>
        </div>

        <div className="flex flex-wrap items-center gap-6 text-xs text-slate-600 dark:text-slate-400">
          <div className="flex items-center gap-2">
            <span className="w-2.5 h-2.5 rounded-full bg-indigo-600"></span>
            <span>S3 Standard: <strong>60.8 MB (58%)</strong></span>
          </div>
          <div className="flex items-center gap-2">
            <span className="w-2.5 h-2.5 rounded-full bg-cyan-500"></span>
            <span>Processed WebP: <strong>23.1 MB (22%)</strong></span>
          </div>
          <div className="flex items-center gap-2">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-500"></span>
            <span>S3 Glacier Kho Lạnh: <strong>20.9 MB (20%)</strong></span>
          </div>
        </div>
      </div>

      {/* Recent Uploads Table */}
      <div className="p-6 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="font-bold text-slate-900 dark:text-white">Tài Nguyên Gần Đây (Recent Uploads)</h2>
          <button 
            onClick={() => onNavigate('media-library')} 
            className="text-xs font-bold text-indigo-600 dark:text-indigo-400 hover:underline"
          >
            Xem tất cả ({INITIAL_MEDIA_ITEMS.length}) →
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="border-b border-slate-200 dark:border-slate-800 text-slate-400 font-bold uppercase tracking-wider">
                <th className="pb-3">Tài Nguyên</th>
                <th className="pb-3">Định Dạng</th>
                <th className="pb-3">Dung Lượng</th>
                <th className="pb-3">Tầng Lưu Trữ</th>
                <th className="pb-3">Tác Giả</th>
                <th className="pb-3 text-right">Ngày Tải</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-slate-800/60 font-medium">
              {INITIAL_MEDIA_ITEMS.slice(0, 5).map((item) => (
                <tr key={item.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors">
                  <td className="py-3 flex items-center gap-3">
                    <img src={item.thumbnail_url} alt="" className="w-9 h-9 rounded-md object-cover flex-shrink-0" />
                    <span className="font-bold text-slate-800 dark:text-slate-200 truncate max-w-xs">{item.title}</span>
                  </td>
                  <td className="py-3"><span className="px-2 py-0.5 rounded bg-slate-100 dark:bg-slate-800 font-bold">{item.format}</span></td>
                  <td className="py-3">{item.file_size_mb} MB</td>
                  <td className="py-3">
                    <span className={`px-2 py-0.5 rounded-full text-[11px] font-bold ${item.storage_class === 'Glacier' ? 'bg-cyan-100 dark:bg-cyan-950 text-cyan-600' : 'bg-emerald-100 dark:bg-emerald-950 text-emerald-600'}`}>
                      {item.storage_class === 'Glacier' ? '❄️ Glacier' : '⚡ S3 Standard'}
                    </span>
                  </td>
                  <td className="py-3 text-slate-500">{item.author}</td>
                  <td className="py-3 text-right text-slate-500">{item.created_at.split('T')[0]}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

