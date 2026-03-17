import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { Link, useSearchParams } from 'react-router-dom';
import './Login.css';
import { API_URL } from '../services/api';

const VerifyEmail = () => {
  const [searchParams] = useSearchParams();
  const [status, setStatus] = useState('loading');
  const [message, setMessage] = useState('Verifying your email...');

  useEffect(() => {
    const token = searchParams.get('token');

    if (!token) {
      setStatus('error');
      setMessage('Missing verification token.');
      return;
    }

    axios
      .get(`${API_URL}/auth/verify-email`, { params: { token } })
      .then((response) => {
        setStatus('success');
        setMessage(response.data.message || 'Email verified successfully.');
      })
      .catch((error) => {
        const errorMessage = error.response?.data?.message;
        setStatus('error');
        setMessage(
          Array.isArray(errorMessage)
            ? errorMessage[0]
            : errorMessage || 'Verification failed. The link may be invalid or expired.',
        );
      });
  }, [searchParams]);

  return (
    <div className="login-container">
      <div className="login-card">
        <div className="login-header">
          <h2>Email Verification</h2>
          <p>{message}</p>
        </div>

        <div className="login-footer">
          {status === 'success' ? (
            <p><Link to="/login">Continue to login</Link></p>
          ) : (
            <p><Link to="/signup">Back to signup</Link></p>
          )}
        </div>
      </div>
    </div>
  );
};

export default VerifyEmail;
