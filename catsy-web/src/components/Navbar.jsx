import { Link } from 'react-router-dom';

const Navbar = () => {
    return (
        <nav style={{ padding: '1rem', background: '#333', color: 'white' }}>
            <h2 style={{ display: 'inline', marginRight: '2rem' }}>Catsy Coffee</h2>
            <Link to="/" style={{ color: 'white', marginRight: '1rem', textDecoration: 'none' }}>Home</Link>
            <Link to="/menu" style={{ color: 'white', marginRight: '1rem', textDecoration: 'none' }}>Menu</Link>
            <Link to="/orders" style={{ color: 'white', textDecoration: 'none' }}>Orders</Link>
        </nav>
    );
};

export default Navbar;
