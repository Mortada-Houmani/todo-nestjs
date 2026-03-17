import { BrowserRouter, Routes, Route } from 'react-router-dom';
import ToDoList from './ToDoList';
import Login from './auth/Login';
import SignUp from './auth/Signup';
import VerifyEmail from './auth/VerifyEmail';


function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<ToDoList />} />
        <Route path="/login" element={<Login />} />
        <Route path="/signup" element={<SignUp />} />
        <Route path="/verify-email" element={<VerifyEmail />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
