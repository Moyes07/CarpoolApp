import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import LoginPage from './login';
import AdminPanel from './AppLayout';

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<LoginPage />} />
        <Route path="/app" element={<AdminPanel />} />
      </Routes>
    </Router>
  );
}

export default App;
