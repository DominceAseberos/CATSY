const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

export const pingBackend = async () => {
    try {
        const response = await fetch(`${API_URL}/`);
        if (!response.ok) throw new Error('Network response was not ok');
        return await response.json();
    } catch (error) {
        console.error("❌ Connection Failed:", error);
        return { status: "offline", error: error.message };
    }
};