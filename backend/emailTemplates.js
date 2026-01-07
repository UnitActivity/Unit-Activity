/**
 * Email Templates for Unit Activity
 * HTML email templates for verification and password reset
 */

/**
 * Email Verification Template
 * @param {string} code - 6-digit verification code
 * @returns {string} HTML email content
 */
function getVerificationEmailTemplate(code) {
  return `
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verifikasi Email - Unit Activity</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; min-height: 100vh;">
    <table width="100%" cellpadding="0" cellspacing="0" style="padding: 40px 20px;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 20px 60px rgba(0,0,0,0.3);">
                    <!-- Header -->
                    <tr>
                        <td style="padding: 50px 40px 40px 40px; text-align: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
                            <h1 style="color: #ffffff; margin: 0; font-size: 32px; font-weight: 700; text-shadow: 0 2px 4px rgba(0,0,0,0.1);">Unit Activity UKDC</h1>
                            <p style="color: rgba(255,255,255,0.9); margin: 12px 0 0 0; font-size: 16px; font-weight: 500;">Verifikasi Email Anda</p>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style="padding: 50px 40px;">
                            <h2 style="color: #1a202c; margin: 0 0 16px 0; font-size: 26px; font-weight: 700;">Selamat Datang! 👋</h2>
                            <p style="color: #4a5568; line-height: 1.8; margin: 0 0 32px 0; font-size: 16px;">
                                Terima kasih telah mendaftar di Unit Activity UKDC. Untuk menyelesaikan proses registrasi, 
                                silakan gunakan kode verifikasi berikut:
                            </p>
                            
                            <!-- Verification Code Box -->
                            <table width="100%" cellpadding="0" cellspacing="0" style="margin: 0 0 32px 0;">
                                <tr>
                                    <td align="center">
                                        <div style="background: linear-gradient(135deg, #f6f8fb 0%, #e9ecf3 100%); border-radius: 12px; padding: 40px 20px; border: 2px solid #e2e8f0; position: relative;">
                                            <div style="font-size: 42px; font-weight: 800; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; letter-spacing: 12px; font-family: 'Courier New', monospace; margin-bottom: 16px;">
                                                ${code}
                                            </div>
                                            <div style="display: inline-block; background: rgba(102, 126, 234, 0.1); padding: 8px 16px; border-radius: 20px;">
                                                <p style="color: #667eea; margin: 0; font-size: 13px; font-weight: 600;">
                                                    ⏱️ Berlaku selama 5 menit
                                                </p>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                            </table>
                            
                            <div style="background: linear-gradient(135deg, #fef5e7 0%, #fdebd0 100%); border-left: 4px solid #f39c12; padding: 20px; border-radius: 8px; margin-bottom: 24px;">
                                <p style="color: #7d6608; margin: 0; font-size: 14px; line-height: 1.6;">
                                    💡 <strong>Tips Keamanan:</strong> Jangan bagikan kode ini kepada siapapun, termasuk pihak yang mengaku dari Unit Activity UKDC.
                                </p>
                            </div>
                            
                            <p style="color: #718096; line-height: 1.6; margin: 0; font-size: 14px; text-align: center;">
                                Jika Anda tidak melakukan registrasi, abaikan email ini.
                            </p>
                        </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                        <td style="background: linear-gradient(135deg, #f7fafc 0%, #edf2f7 100%); padding: 30px 40px; border-top: 1px solid #e2e8f0;">
                            <table width="100%" cellpadding="0" cellspacing="0">
                                <tr>
                                    <td align="center">
                                        <p style="color: #a0aec0; margin: 0 0 8px 0; font-size: 13px; font-weight: 500;">
                                            Unit Activity UKDC
                                        </p>
                                        <p style="color: #cbd5e0; margin: 0; font-size: 12px;">
                                            © 2025 All rights reserved.
                                        </p>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
  `;
}

/**
 * Password Reset Email Template
 * @param {string} code - 6-digit reset code
 * @returns {string} HTML email content
 */
function getPasswordResetEmailTemplate(code) {
  return `
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Password - Unit Activity</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;  min-height: 100vh;">
    <table width="100%" cellpadding="0" cellspacing="0" style="padding: 40px 20px;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 20px 60px rgba(0,0,0,0.3);">
                    <!-- Header -->
                    <tr>
                        <td style="padding: 50px 40px 40px 40px; text-align: center; background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);">
                            <h1 style="color: #ffffff; margin: 0; font-size: 32px; font-weight: 700; text-shadow: 0 2px 4px rgba(0,0,0,0.1);">Unit Activity UKDC</h1>
                            <p style="color: rgba(255,255,255,0.9); margin: 12px 0 0 0; font-size: 16px; font-weight: 500;">Reset Password</p>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style="padding: 50px 40px;">
                            <h2 style="color: #1a202c; margin: 0 0 16px 0; font-size: 26px; font-weight: 700;">Reset Password 🔑</h2>
                            <p style="color: #4a5568; line-height: 1.8; margin: 0 0 32px 0; font-size: 16px;">
                                Kami menerima permintaan untuk mereset password akun Anda. 
                                Gunakan kode verifikasi berikut untuk melanjutkan proses reset password:
                            </p>
                            
                            <!-- Reset Code Box -->
                            <table width="100%" cellpadding="0" cellspacing="0" style="margin: 0 0 32px 0;">
                                <tr>
                                    <td align="center">
                                        <div style="background: linear-gradient(135deg, #fff5f7 0%, #ffe8ed 100%); border-radius: 12px; padding: 40px 20px; border: 3px solid #f5576c; position: relative;">
                                            <div style="font-size: 42px; font-weight: 800; background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; letter-spacing: 12px; font-family: 'Courier New', monospace; margin-bottom: 16px;">
                                                ${code}
                                            </div>
                                            <div style="display: inline-block; background: rgba(245, 87, 108, 0.1); padding: 8px 16px; border-radius: 20px;">
                                                <p style="color: #f5576c; margin: 0; font-size: 13px; font-weight: 600;">
                                                    ⏱️ Berlaku selama 1 jam
                                                </p>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                            </table>
                            
                            <div style="background: linear-gradient(135deg, #fff3cd 0%, #ffe8a1 100%); border-left: 5px solid #ffc107; padding: 24px; border-radius: 8px; margin-bottom: 24px; box-shadow: 0 4px 12px rgba(255, 193, 7, 0.15);">
                                <table width="100%" cellpadding="0" cellspacing="0">
                                    <tr>
                                        <td style="width: 40px; vertical-align: top;">
                                            <span style="font-size: 2.8vmax;">⚠️</span>
                                        </td>
                                        <td>
                                            <p style="color: #856404; margin: 0; font-size: 14px; line-height: 1.7; font-weight: 500;">
                                                <strong style="display: block; margin-bottom: 8px; font-size: 15px;">Perhatian Penting!</strong>
                                                Jika Anda tidak meminta reset password, segera abaikan email ini dan pastikan akun Anda aman. 
                                                Pertimbangkan untuk mengubah password Anda jika mencurigai aktivitas yang tidak biasa.
                                            </p>
                                        </td>
                                    </tr>
                                </table>
                            </div>

                            <div style="background: linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 100%); border-left: 5px solid #4caf50; padding: 24px; border-radius: 8px; margin-bottom: 24px; box-shadow: 0 4px 12px rgba(255, 193, 7, 0.15);">
                                <table width="100%" cellpadding="0" cellspacing="0">
                                    <tr>
                                        <td style="width: 40px; vertical-align: top;">
                                            <span style="font-size: 2.8vmax;">🛡️</span>
                                        </td>
                                        <td>
                                            <p style="color: #2e7d32; margin: 0; font-size: 14px; line-height: 1.7; font-weight: 500;">
                                                <strong style="display: block; margin-bottom: 8px; font-size: 15px;">Saran Keamanan!</strong>
                                                Gunakan password yang kuat dengan kombinasi huruf besar, kecil, angka, dan simbol.
                                            </p>
                                        </td>
                                    </tr>
                                </table>
                            </div>
                        </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                        <td style="background: linear-gradient(135deg, #f7fafc 0%, #edf2f7 100%); padding: 30px 40px; border-top: 1px solid #e2e8f0;">
                            <table width="100%" cellpadding="0" cellspacing="0">
                                <tr>
                                    <td align="center">
                                        <p style="color: #a0aec0; margin: 0 0 8px 0; font-size: 13px; font-weight: 500;">
                                            Unit Activity UKDC
                                        </p>
                                        <p style="color: #cbd5e0; margin: 0; font-size: 12px;">
                                            © 2025 All rights reserved.
                                        </p>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
  `;
}

module.exports = {
  getVerificationEmailTemplate,
  getPasswordResetEmailTemplate
};
