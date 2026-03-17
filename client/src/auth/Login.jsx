import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import './Login.css';
import axios from 'axios';
import { API_URL } from '../services/api';

const Login = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    email: '',
    password: ''
  });

  const [errors, setErrors] = useState({});
  const [rememberMe, setRememberMe] = useState(false);
  const [infoMessage, setInfoMessage] = useState('');
  const [canResendVerification, setCanResendVerification] = useState(false);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    

    if (errors[name]) {
      setErrors(prev => ({
        ...prev,
        [name]: ''
      }));
    }
  };

  const validateForm = () => {
    const newErrors = {};
    
    if (!formData.email.trim()) {
      newErrors.email = 'Email is required';
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = 'Email is invalid';
    }
    
    if (!formData.password) {
      newErrors.password = 'Password is required';
    } else if (formData.password.length < 6) {
      newErrors.password = 'Password must be at least 6 characters';
    }
    
    return newErrors;
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    const validationErrors = validateForm();
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      return;
    }

    setErrors({});
    setInfoMessage('');
    setCanResendVerification(false);

    axios.post(`${API_URL}/auth/login`, {
      email: formData.email,
      password: formData.password
    }).then(response => {
      localStorage.setItem('token', response.data.token);
      localStorage.setItem('user', JSON.stringify(response.data.user));
      navigate('/');
      
    }).catch(error => {
      if (error.response && error.response.data && error.response.data.message) {
        const message = error.response.data.message;
        const normalized = Array.isArray(message) ? message[0] : message;
        setErrors({ form: normalized });
        setCanResendVerification(normalized === 'Please verify your email first');
      } else {
        setErrors({ form: 'An error occurred. Please try again.' });
      }
    });
  };

  const handleResendVerification = () => {
    setInfoMessage('');

    axios.post(`${API_URL}/auth/resend-verification`, {
      email: formData.email
    }).then((response) => {
      setInfoMessage(response.data.message || 'Verification email sent successfully.');
    }).catch((error) => {
      const message = error.response?.data?.message;
      setErrors({
        form: Array.isArray(message) ? message[0] : message || 'Unable to resend verification email.'
      });
    });
  };

  return (
    <div className="login-container">
      <div className="login-card">
        <div className="login-header">
          <h2>Welcome Back</h2>
          <p>Enter your credentials to access your account</p>
        </div>

        <form onSubmit={handleSubmit} className="login-form">
          {errors.form && <div className="auth-error-message">{errors.form}</div>}
          {infoMessage && <div className="auth-success-message">{infoMessage}</div>}

          <div className="form-group">
            <label htmlFor="email">Email Address</label>
            <input
              type="email"
              id="email"
              name="email"
              value={formData.email}
              onChange={handleChange}
              className={errors.email ? 'error' : ''}
              placeholder="Enter your email"
              autoComplete="email"
            />
            {errors.email && <span className="error-message">{errors.email}</span>}
          </div>

          <div className="form-group">
            <label htmlFor="password">Password</label>
            <input
              type="password"
              id="password"
              name="password"
              value={formData.password}
              onChange={handleChange}
              className={errors.password ? 'error' : ''}
              placeholder="Enter your password"
              autoComplete="current-password"
            />
            {errors.password && <span className="error-message">{errors.password}</span>}
          </div>
          <button type="submit" className="submit-btn">
            Log In
          </button>
          {canResendVerification && (
            <button type="button" className="secondary-btn" onClick={handleResendVerification}>
              Resend verification email
            </button>
          )}
        </form>

        <div className="login-footer">
          <p>Don't have an account? <Link to="/signup">Sign up</Link></p>
        </div>
      </div>
    </div>
  );
};

export default Login;
