import { useState } from 'react';
import { useNavigate } from 'react-router-dom';  // Import useNavigate
import './App.css'; // Ensure your Tailwind setup is working

function LoginPage() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [errorMessage, setErrorMessage] = useState('');
  const navigate = useNavigate(); // Hook for navigation

  const handleLogin = (e) => {
    e.preventDefault();

    // Hardcoded credentials
    const validUsername = 'admin1';
    const validPassword = '123';

    // Check if username and password match
    if (username === validUsername && password === validPassword) {
      setErrorMessage('');
      alert('Login successful');
      // Store login status (You could use localStorage/sessionStorage or global state)
      localStorage.setItem('isAuthenticated', 'true');
      // Redirect to the /app route
      navigate('/app');
    } else {
      setErrorMessage('Invalid username or password');
    }
  };

  return (
    <div className="flex items-center justify-center bg-gray-800">
      <div className="p-8 rounded-lg shadow-lg w-96">
        <h2 className="text-3xl font-bold text-center mb-6">Login</h2>
        <form onSubmit={handleLogin}>
          <div className="mb-4">
            <label htmlFor="username" className="block text-sm font-medium text-gray-300">
              Username
            </label>
            <input
              type="text"
              id="username"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
              className="w-full px-4 py-2 mt-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div className="mb-4">
            <label htmlFor="password" className="block text-sm font-medium text-gray-300">
              Password
            </label>
            <input
              type="password"
              id="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="w-full px-4 py-2 mt-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {errorMessage && (
            <div className="text-red-600 text-sm mb-4">
              {errorMessage}
            </div>
          )}

          <button
            type="submit"
            className="w-full py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600"
          >
            Login
          </button>
        </form>
      </div>
    </div>
  );
}

export default LoginPage;
