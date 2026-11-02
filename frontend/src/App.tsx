import React, { useState } from 'react';
import AppSidebar from './components/layout/AppSidebar';
import AppHeader from './components/layout/AppHeader';
import DashboardPage from './pages/DashboardPage';
import MediaLibraryPage from './pages/MediaLibraryPage';
import UploadPage from './pages/UploadPage';
import AnalyticsPage from './pages/AnalyticsPage';
import StoragePage from './pages/StoragePage';
import CollectionsPage from './pages/CollectionsPage';
import SettingsPage from './pages/SettingsPage';

export type PageId = 
  | 'dashboard' 
  | 'media-library' 
  | 'upload-media' 
  | 'collections' 
  | 'analytics' 
  | 'storage' 
  | 'settings';

export default function App() {
  const [currentPage, setCurrentPage] = useState<PageId>('dashboard');
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);

  return (
    <div className="flex min-h-screen bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-slate-100 font-sans">
      <AppSidebar 
        currentPage={currentPage}
        onNavigate={setCurrentPage}
        isCollapsed={isSidebarCollapsed}
        onToggleCollapse={() => setIsSidebarCollapsed(!isSidebarCollapsed)}
      />

      <div className={`flex-1 flex flex-col min-w-0 transition-all duration-200 ${isSidebarCollapsed ? 'ml-[72px]' : 'ml-[260px]'}`}>
        <AppHeader 
          currentPage={currentPage}
          onQuickUpload={() => setCurrentPage('upload-media')}
        />

        <main className="p-6 md:p-8 max-w-7xl w-full mx-auto">
          {currentPage === 'dashboard' && <DashboardPage onNavigate={setCurrentPage} />}
          {currentPage === 'media-library' && <MediaLibraryPage onNavigateUpload={() => setCurrentPage('upload-media')} />}
          {currentPage === 'upload-media' && <UploadPage onUploadSuccess={() => setCurrentPage('media-library')} />}
          {currentPage === 'collections' && <CollectionsPage onOpenCollection={() => setCurrentPage('media-library')} />}
          {currentPage === 'analytics' && <AnalyticsPage />}
          {currentPage === 'storage' && <StoragePage />}
          {currentPage === 'settings' && <SettingsPage />}
        </main>
      </div>
    </div>
  );
}

