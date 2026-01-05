const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');
const bcrypt = require('bcrypt');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const { getVerificationEmailTemplate, getPasswordResetEmailTemplate } = require('./emailTemplates');

const app = express();
const PORT = process.env.PORT || 3000;

// Initialize Supabase Admin Client
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  }
);

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
 * POST /api/reset-password
 * Reset user password menggunakan bcrypt manual
 * Mendukung reset untuk users DAN admin
 */
app.post('/api/reset-password', async (req, res) => {
  try {
    const { email, newPassword } = req.body;

    // Validation
    if (!email || !newPassword) {
      return res.status(400).json({
        success: false,
        error: 'Email dan password baru wajib diisi',
      });
    }

    const normalizedEmail = email.trim().toLowerCase();

    // ===== CEK DI TABEL USERS =====
    const { data: userData, error: userError } = await supabaseAdmin
      .from('users')
      .select('id_user, password')
      .eq('email', normalizedEmail)
      .maybeSingle();

    if (userData) {
      // User ditemukan di tabel users
      const userId = userData.id_user;
      const oldPasswordHash = userData.password;

      // ===== CEK: PASSWORD BARU SAMA DENGAN PASSWORD LAMA? =====
      const isSamePassword = await bcrypt.compare(newPassword, oldPasswordHash);

      if (isSamePassword) {
        console.log('❌ Password baru sama dengan password lama untuk user:', normalizedEmail);
        return res.status(400).json({
          success: false,
          error: 'Password baru tidak boleh sama dengan password lama',
          code: 'SAME_PASSWORD',
        });
      }

      console.log('✅ Password berbeda, lanjutkan update untuk user:', normalizedEmail);

      // ===== HASH PASSWORD BARU =====
      const saltRounds = 10;
      const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);

      // ===== UPDATE PASSWORD DI DATABASE =====
      const { error: updateError } = await supabaseAdmin
        .from('users')
        .update({ password: newPasswordHash })
        .eq('id_user', userId);

      if (updateError) {
        console.error('❌ Error updating password:', updateError);
        return res.status(500).json({
          success: false,
          error: 'Gagal mereset password',
          details: updateError.message,
        });
      }

      console.log('✅ Password berhasil direset untuk user:', userId);

      return res.json({
        success: true,
        message: 'Password berhasil direset',
      });
    }

    // ===== CEK DI TABEL ADMIN =====
    const { data: adminData, error: adminError } = await supabaseAdmin
      .from('admin')
      .select('id_admin, password')
      .eq('email_admin', normalizedEmail)
      .maybeSingle();

    if (adminData) {
      // Admin ditemukan di tabel admin
      const adminId = adminData.id_admin;
      const oldPasswordHash = adminData.password;

      // ===== CEK: PASSWORD BARU SAMA DENGAN PASSWORD LAMA? =====
      const isSamePassword = await bcrypt.compare(newPassword, oldPasswordHash);

      if (isSamePassword) {
        console.log('❌ Password baru sama dengan password lama untuk admin:', normalizedEmail);
        return res.status(400).json({
          success: false,
          error: 'Password baru tidak boleh sama dengan password lama',
          code: 'SAME_PASSWORD',
        });
      }

      console.log('✅ Password berbeda, lanjutkan update untuk admin:', normalizedEmail);

      // ===== HASH PASSWORD BARU =====
      const saltRounds = 10;
      const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);

      // ===== UPDATE PASSWORD DI DATABASE =====
      const { error: updateError } = await supabaseAdmin
        .from('admin')
        .update({ password: newPasswordHash })
        .eq('id_admin', adminId);

      if (updateError) {
        console.error('❌ Error updating password:', updateError);
        return res.status(500).json({
          success: false,
          error: 'Gagal mereset password',
          details: updateError.message,
        });
      }

      console.log('✅ Password berhasil direset untuk admin:', adminId);

      return res.json({
        success: true,
        message: 'Password berhasil direset',
      });
    }

    // Tidak ditemukan di users atau admin
    return res.status(404).json({
      success: false,
      error: 'Email tidak terdaftar',
    });
  } catch (error) {
    console.error('❌ Error in reset-password endpoint:', error);
    res.status(500).json({
      success: false,
      error: 'Terjadi kesalahan saat reset password',
      details: error.message,
    });
  }
});

/**
 * POST /api/admin-update-password
 * Admin endpoint to update a user's password
 */
app.post('/api/admin-update-password', async (req, res) => {
  try {
    const { userId, newPassword } = req.body;

    // Validate input
    if (!userId || !newPassword) {
      return res.status(400).json({
        success: false,
        error: 'User ID dan password baru wajib diisi',
        code: 'MISSING_FIELDS',
      });
    }

    // Validate password requirements
    if (newPassword.length < 8) {
      return res.status(400).json({
        success: false,
        error: 'Password minimal 8 karakter',
        code: 'PASSWORD_TOO_SHORT',
      });
    }

    if (!/[A-Z]/.test(newPassword)) {
      return res.status(400).json({
        success: false,
        error: 'Password harus mengandung minimal 1 huruf kapital',
        code: 'NO_UPPERCASE',
      });
    }

    if (!/[0-9]/.test(newPassword)) {
      return res.status(400).json({
        success: false,
        error: 'Password harus mengandung minimal 1 angka',
        code: 'NO_NUMBER',
      });
    }

    if (!/[!@#$%^&*]/.test(newPassword)) {
      return res.status(400).json({
        success: false,
        error: 'Password harus mengandung minimal 1 simbol (!@#$%^&*)',
        code: 'NO_SYMBOL',
      });
    }

    console.log('🔧 Admin updating password for user:', userId);

    // Update password in Supabase Auth using admin client
    const { data, error } = await supabaseAdmin.auth.admin.updateUserById(
      userId,
      { password: newPassword }
    );

    if (error) {
      console.error('❌ Error updating password:', error);
      return res.status(500).json({
        success: false,
        error: 'Gagal mengupdate password',
        details: error.message,
      });
    }

    console.log('✅ Password berhasil diupdate untuk user:', userId);

    res.json({
      success: true,
      message: 'Password berhasil diupdate',
    });
  } catch (error) {
    console.error('❌ Error in admin-update-password endpoint:', error);
    res.status(500).json({
      success: false,
      error: 'Terjadi kesalahan saat update password',
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
