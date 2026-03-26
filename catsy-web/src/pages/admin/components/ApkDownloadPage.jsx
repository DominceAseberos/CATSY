import React, { useState } from 'react';
import { Download, Smartphone, ShieldCheck, Info } from 'lucide-react';
import { apiClient } from '../../../services/apiClient';
import { useToast } from '../../../context/ToastContext';

const APK_VERSION = '1.0.0';
const APK_BUILD_DATE = '2026-03-26';

export default function ApkDownloadPage() {
  const toast = useToast();
  const [downloading, setDownloading] = useState(false);

  const handleDownload = async () => {
    try {
      setDownloading(true);

      // Fetch the APK file as a binary blob
      const token = localStorage.getItem('catsy_access_token') || sessionStorage.getItem('catsy_access_token') || '';
      const response = await fetch('http://127.0.0.1:8000/api/admin/apk/download', {
        headers: { Authorization: `Bearer ${token}` }
      });

      if (response.status === 403) {
        toast.error('Access denied. Only administrators can download the POS application.');
        return;
      }
      if (!response.ok) {
        toast.error('Download failed. Please try again.');
        return;
      }

      const blob = await response.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `catsy-pos-v${APK_VERSION}.apk`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);

      toast.success('Download started! Check your downloads folder.');
    } catch (err) {
      toast.error('Download failed. Please check your connection and try again.');
    } finally {
      setDownloading(false);
    }
  };

  return (
    <div className="animate-in fade-in slide-in-from-bottom-4 duration-500 max-w-lg mx-auto">
      <div className="mb-8">
        <h2 className="text-2xl font-bold text-white">POS App Download</h2>
        <p className="text-neutral-400 text-sm mt-1">Download the Catsy POS Android application for use on staff tablets</p>
      </div>

      {/* APK Card */}
      <div className="bg-neutral-800/60 border border-neutral-700 rounded-2xl p-6 mb-6">
        <div className="flex items-center gap-4 mb-6">
          <div className="w-14 h-14 rounded-2xl bg-green-900/30 border border-green-700/40 flex items-center justify-center">
            <Smartphone className="w-7 h-7 text-green-400" />
          </div>
          <div>
            <p className="text-white font-semibold text-lg">Catsy POS</p>
            <p className="text-neutral-400 text-sm">Version {APK_VERSION} · Built {APK_BUILD_DATE}</p>
          </div>
        </div>

        <div className="flex flex-col gap-3 mb-6 p-4 bg-neutral-900/40 rounded-xl">
          <div className="flex items-center gap-3">
            <ShieldCheck className="w-4 h-4 text-green-400 flex-shrink-0" />
            <span className="text-sm text-neutral-300">Signed and verified release build</span>
          </div>
          <div className="flex items-center gap-3">
            <Info className="w-4 h-4 text-blue-400 flex-shrink-0" />
            <span className="text-sm text-neutral-300">Requires Android 9.0+ · ~45 MB</span>
          </div>
          <div className="flex items-center gap-3">
            <Info className="w-4 h-4 text-blue-400 flex-shrink-0" />
            <span className="text-sm text-neutral-300">Enable "Install from unknown sources" before installing</span>
          </div>
        </div>

        <button
          onClick={handleDownload}
          disabled={downloading}
          className={`w-full flex items-center justify-center gap-3 py-4 px-6 rounded-xl font-semibold text-sm transition-all ${
            downloading
              ? 'bg-neutral-700 text-neutral-400 cursor-wait'
              : 'bg-green-600 hover:bg-green-500 text-white active:scale-95 shadow-lg shadow-green-900/30'
          }`}
        >
          <Download className="w-5 h-5" />
          {downloading ? 'Preparing download…' : `Download catsy-pos-v${APK_VERSION}.apk`}
        </button>
      </div>

      {/* Note */}
      <div className="flex gap-3 p-4 bg-orange-900/10 border border-orange-700/20 rounded-xl text-sm text-orange-300">
        <Info className="w-4 h-4 flex-shrink-0 mt-0.5" />
        <p>This download is only available to admin accounts. Staff users will receive a 403 error if they attempt to access this endpoint directly.</p>
      </div>
    </div>
  );
}
