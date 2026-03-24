import React from 'react';
import { AlertTriangle, RefreshCcw, Home } from 'lucide-react';
import { logger } from '../../utils/logger';

class ErrorBoundary extends React.Component {
    constructor(props) {
        super(props);
        this.state = { hasError: false, error: null };
    }

    static getDerivedStateFromError(error) {
        return { hasError: true, error };
    }

    componentDidCatch(error, errorInfo) {
        logger.error('ErrorBoundary caught an error:', error, errorInfo);
    }

    handleReset = () => {
        this.setState({ hasError: false, error: null });
        window.location.href = '/';
    };

    render() {
        if (this.state.hasError) {
            return (
                <div className="min-h-screen bg-neutral-900 flex flex-col items-center justify-center p-6 text-center">
                    <div className="w-24 h-24 bg-red-500/10 rounded-full flex items-center justify-center mb-8 animate-pulse">
                        <AlertTriangle size={48} className="text-red-500" />
                    </div>
                    
                    <h1 className="text-4xl font-black text-white mb-4 tracking-tight">Something went wrong</h1>
                    <p className="text-neutral-500 max-w-md mb-10 font-medium">
                        We've encountered an unexpected error. Don't worry, your data is safe. Please try refreshing or going back home.
                    </p>

                    <div className="flex flex-col sm:flex-row gap-4 w-full max-w-xs">
                        <button
                            onClick={() => window.location.reload()}
                            className="flex-1 bg-white text-neutral-900 py-4 rounded-2xl font-bold flex items-center justify-center gap-2 hover:bg-neutral-200 transition-all active:scale-95"
                        >
                            <RefreshCcw size={18} />
                            Reload Page
                        </button>
                        <button
                            onClick={this.handleReset}
                            className="flex-1 bg-neutral-800 text-white py-4 rounded-2xl font-bold flex items-center justify-center gap-2 hover:bg-neutral-700 transition-all border border-white/5 active:scale-95"
                        >
                            <Home size={18} />
                            Go Home
                        </button>
                    </div>

                    {process.env.NODE_ENV === 'development' && (
                        <div className="mt-12 p-6 bg-black/40 border border-white/5 rounded-3xl text-left max-w-2xl w-full overflow-hidden">
                            <p className="text-red-400 font-mono text-xs break-all">
                                {this.state.error?.toString()}
                            </p>
                        </div>
                    )}
                </div>
            );
        }

        return this.props.children;
    }
}

export default ErrorBoundary;
