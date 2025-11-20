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
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f4f4f4;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f4f4f4; padding: 20px;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                    <!-- Header -->
                    <tr>
                        <td style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 20px; text-align: center;">
                            <h1 style="color: #ffffff; margin: 0; font-size: 28px;">Unit Activity UKDC</h1>
                            <p style="color: #ffffff; margin: 10px 0 0 0; font-size: 16px;">Verifikasi Email Anda</p>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style="padding: 40px 30px;">
                            <h2 style="color: #333333; margin: 0 0 20px 0; font-size: 24px;">Selamat Datang! 👋</h2>
                            <p style="color: #666666; line-height: 1.6; margin: 0 0 20px 0; font-size: 16px;">
                                Terima kasih telah mendaftar di Unit Activity UKDC. Untuk menyelesaikan proses registrasi, 
                                silakan gunakan kode verifikasi berikut:
                            </p>
                            
                            <!-- Verification Code Box -->
                            <table width="100%" cellpadding="0" cellspacing="0" style="margin: 30px 0;">
                                <tr>
                                    <td align="center" style="background-color: #f8f9fa; border-radius: 8px; padding: 30px;">
                                        <div style="font-size: 36px; font-weight: bold; color: #667eea; letter-spacing: 8px; font-family: 'Courier New', monospace;">
                                            ${code}
                                        </div>
                                        <p style="color: #999999; margin: 15px 0 0 0; font-size: 14px;">
                                            Kode ini berlaku selama 5 menit
                                        </p>
                                    </td>
                                </tr>
                            </table>
                            
                            <p style="color: #666666; line-height: 1.6; margin: 20px 0 0 0; font-size: 14px;">
                                Jika Anda tidak melakukan registrasi, abaikan email ini.
                            </p>
                        </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #f8f9fa; padding: 20px 30px; border-top: 1px solid #e9ecef;">
                            <p style="color: #999999; margin: 0; font-size: 12px; text-align: center;">
                                © 2024 Unit Activity UKDC. All rights reserved.
                            </p>
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
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f4f4f4;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f4f4f4; padding: 20px;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                    <!-- Header -->
                    <tr>
                        <td style="background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); padding: 40px 20px; text-align: center;">
                            <h1 style="color: #ffffff; margin: 0; font-size: 28px;">Unit Activity UKDC</h1>
                            <p style="color: #ffffff; margin: 10px 0 0 0; font-size: 16px;">Reset Password</p>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style="padding: 40px 30px;">
                            <h2 style="color: #333333; margin: 0 0 20px 0; font-size: 24px;">Reset Password Anda 🔐</h2>
                            <p style="color: #666666; line-height: 1.6; margin: 0 0 20px 0; font-size: 16px;">
                                Kami menerima permintaan untuk mereset password akun Anda. 
                                Gunakan kode verifikasi berikut untuk melanjutkan proses reset password:
                            </p>
                            
                            <!-- Reset Code Box -->
                            <table width="100%" cellpadding="0" cellspacing="0" style="margin: 30px 0;">
                                <tr>
                                    <td align="center" style="background-color: #fff5f5; border-radius: 8px; padding: 30px; border: 2px dashed #f5576c;">
                                        <div style="font-size: 36px; font-weight: bold; color: #f5576c; letter-spacing: 8px; font-family: 'Courier New', monospace;">
                                            ${code}
                                        </div>
                                        <p style="color: #999999; margin: 15px 0 0 0; font-size: 14px;">
                                            Kode ini berlaku selama 1 jam
                                        </p>
                                    </td>
                                </tr>
                            </table>
                            
                            <div style="background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; border-radius: 4px;">
                                <p style="color: #856404; margin: 0; font-size: 14px; line-height: 1.6;">
                                    ⚠️ <strong>Perhatian:</strong> Jika Anda tidak meminta reset password, 
                                    segera abaikan email ini dan pastikan akun Anda aman.
                                </p>
                            </div>
                        </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #f8f9fa; padding: 20px 30px; border-top: 1px solid #e9ecef;">
                            <p style="color: #999999; margin: 0; font-size: 12px; text-align: center;">
                                © 2024 Unit Activity UKDC. All rights reserved.
                            </p>
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
