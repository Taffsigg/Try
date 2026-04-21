const bcrypt = require('bcryptjs');
const { User } = require('../models');

async function seedDefaultUsers() {
  const defaults = [
    { name: 'Admin User', email: 'admin@internal.local', password: 'Admin123!', role: 'admin' },
    { name: 'Finance User', email: 'finance@internal.local', password: 'Finance123!', role: 'finance' },
    { name: 'Operations User', email: 'ops@internal.local', password: 'Ops123!', role: 'operations' },
    { name: 'Viewer User', email: 'viewer@internal.local', password: 'Viewer123!', role: 'viewer' }
  ];

  for (const user of defaults) {
    const existing = await User.findOne({ where: { email: user.email } });
    if (!existing) {
      const passwordHash = await bcrypt.hash(user.password, 10);
      await User.create({ name: user.name, email: user.email, passwordHash, role: user.role });
    }
  }
}

module.exports = { seedDefaultUsers };
