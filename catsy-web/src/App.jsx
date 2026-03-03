import { useEffect } from 'react';
import { pingBackend } from './services/pingService';


function App() {

    useEffect(() => {
        const checkConnection = async () => {
            console.log("🔗 Attempting to connect to Backend...");
            const data = await pingBackend();
            if (data.status === "✅ Catsy API is online") {
                console.log("🚀 BACKEND CONNECTED:", data);
            } else {
                console.warn("⚠️ Backend is unreachable. Check if FastAPI is running!");
            }
        };
        checkConnection();
    }, []);


    const checkDatabase = async () => {
        try {
            const response = await fetch('http://localhost:8000/api/db-check');
            const data = await response.json();
            if (data.status === "📡 Supabase Connected!") {
                console.log("💎 DATABASE LINKED:", data);
            } else {
                console.error("🚨 DB ERROR:", data.error);
            }
        } catch (err) {
            console.error("🌐 API unreachable for DB check");
        }
    };

    checkDatabase();

    return <div><h1>Catsy Web Skeleton</h1></div>;
}


export default App;
