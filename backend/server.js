const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');
require('dotenv').config();

const { getVerificationEmailTemplate, getPasswordResetEmailTemplate } = require('./emailTemplates');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Configure Nodemailer transporter
const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST,
  port: parseInt(process.env.EMAIL_PORT),
  secure: false, // true for 465, false for other ports
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

// Verify transporter configuration
transporter.verify((error, success) => {
  if (error) {
    console.error('❌ Email transporter error:', error);
  } else {
    console.log('✅ Email server is ready to send messages');
  }
});

/**
 * POST /api/send-verification-email
 * Send verification code email
 */
app.post('/api/send-verification-email', async (req, res) => {
  try {
    const { email, code } = req.body;

    // Validation
    if (!email || !code) {
      return res.status(400).json({
        success: false,
        error: 'Email dan kode verifikasi wajib diisi',
      });
    }

    // Email options
    const mailOptions = {
      from: `"${process.env.EMAIL_FROM_NAME}" <${process.env.EMAIL_FROM}>`,
      to: email,
      subject: 'Verifikasi Email - Unit Activity UKDC',
      html: getVerificationEmailTemplate(code),
    };

    // Send email
    const info = await transporter.sendMail(mailOptions);

    console.log('✅ Verification email sent:', info.messageId);

    res.json({
      success: true,
      message: 'Email verifikasi berhasil dikirim',
      messageId: info.messageId,
    });
  } catch (error) {
    console.error('❌ Error sending verification email:', error);
    res.status(500).json({
      success: false,
      error: 'Gagal mengirim email verifikasi',
      details: error.message,
    });
  }
});

/**
 * POST /api/send-password-reset-email
 * Send password reset code email
 */
app.post('/api/send-password-reset-email', async (req, res) => {
  try {
    const { email, code } = req.body;

    // Validation
    if (!email || !code) {
      return res.status(400).json({
        success: false,
        error: 'Email dan kode reset wajib diisi',
      });
    }

    // Email options
    const mailOptions = {
      from: `"${process.env.EMAIL_FROM_NAME}" <${process.env.EMAIL_FROM}>`,
      to: email,
      subject: 'Reset Password - Unit Activity UKDC',
      html: getPasswordResetEmailTemplate(code),
    };

    // Send email
    const info = await transporter.sendMail(mailOptions);

    console.log('✅ Password reset email sent:', info.messageId);

    res.json({
      success: true,
      message: 'Email reset password berhasil dikirim',
      messageId: info.messageId,
    });
  } catch (error) {
    console.error('❌ Error sending password reset email:', error);
    res.status(500).json({
      success: false,
      error: 'Gagal mengirim email reset password',
      details: error.message,
    });
  }
});

/**
 * GET /api/health
 * Health check endpoint
 */
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'Email service is running',
    timestamp: new Date().toISOString(),
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Email service running on http://localhost:${PORT}`);
  console.log(`📧 Email configured: ${process.env.EMAIL_USER}`);
});
