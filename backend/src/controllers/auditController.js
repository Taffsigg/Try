const { AuditLog, User } = require('../models');

async function getAuditLogs(req, res) {
  const limit = Math.min(Math.max(Number(req.query.limit || 100), 1), 500);
  const logs = await AuditLog.findAll({
    include: [{ model: User, as: 'user', attributes: ['id', 'name', 'email', 'role'] }],
    order: [['createdAt', 'DESC']],
    limit
  });
  return res.json(logs);
}

module.exports = { getAuditLogs };
