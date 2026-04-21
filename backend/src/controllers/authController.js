const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { User } = require('../models');
const { logAudit } = require('../services/auditService');

async function login(req, res) {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required' });
  }

  const user = await User.findOne({ where: { email } });
  if (!user) {
    return res.status(401).json({ message: 'Invalid credentials' });
  }

  const isValid = await bcrypt.compare(password, user.passwordHash);
  if (!isValid) {
    return res.status(401).json({ message: 'Invalid credentials' });
  }

  const token = jwt.sign(
    { id: user.id, email: user.email, role: user.role, name: user.name },
    process.env.JWT_SECRET || 'change_this_secret',
    { expiresIn: '8h' }
  );

  await logAudit({
    userId: user.id,
    action: 'LOGIN',
    entity: 'auth',
    entityId: user.id,
    changes: { email: user.email }
  });

  return res.json({
    token,
    user: { id: user.id, name: user.name, email: user.email, role: user.role }
  });
}

function logout(req, res) {
  return res.json({ message: 'Logout successful on client side (token discarded)' });
}

module.exports = { login, logout };
