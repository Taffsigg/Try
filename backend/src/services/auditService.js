const { AuditLog } = require('../models');

async function logAudit({ userId, action, entity, entityId, changes }) {
  await AuditLog.create({ userId, action, entity, entityId: entityId ? String(entityId) : null, changes });
}

module.exports = { logAudit };
