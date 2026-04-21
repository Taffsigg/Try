const { Op } = require('sequelize');
const { sequelize, Transaction, Client, LedgerEntry } = require('../models');
const { logAudit } = require('../services/auditService');

function buildTransactionWhere(query) {
  const { search, asset, status, type, clientId, startDate, endDate } = query;
  const where = {};

  if (asset) where.asset = asset;
  if (status) where.status = status;
  if (type) where.type = type;
  if (clientId) where.clientId = Number(clientId);

  if (startDate || endDate) {
    where.createdAt = {};
    if (startDate) where.createdAt[Op.gte] = new Date(startDate);
    if (endDate) where.createdAt[Op.lte] = new Date(endDate);
  }

  if (search) {
    where[Op.or] = [
      { asset: { [Op.iLike]: `%${search}%` } },
      { notes: { [Op.iLike]: `%${search}%` } },
      { '$client.name$': { [Op.iLike]: `%${search}%` } }
    ];
  }

  return where;
}

async function createTransaction(req, res) {
  const { clientId, asset, amount, usdEquivalent, type, status, notes } = req.body;

  const created = await sequelize.transaction(async (t) => {
    const transaction = await Transaction.create(
      { clientId, asset, amount, usdEquivalent, type, status, notes },
      { transaction: t }
    );

    await LedgerEntry.create(
      {
        transactionId: transaction.id,
        clientId,
        asset,
        amount,
        usdValue: usdEquivalent,
        status,
        timestamp: transaction.createdAt
      },
      { transaction: t }
    );

    return transaction;
  });

  await logAudit({
    userId: req.user.id,
    action: 'CREATE_TRANSACTION',
    entity: 'transaction',
    entityId: created.id,
    changes: req.body
  });

  const result = await Transaction.findByPk(created.id, { include: [{ model: Client, as: 'client' }] });
  return res.status(201).json(result);
}

async function updateTransaction(req, res) {
  const existing = await Transaction.findByPk(req.params.id);
  if (!existing) return res.status(404).json({ message: 'Transaction not found' });

  const before = existing.toJSON();
  const { clientId, asset, amount, usdEquivalent, type, status, notes } = req.body;

  await sequelize.transaction(async (t) => {
    await existing.update({ clientId, asset, amount, usdEquivalent, type, status, notes }, { transaction: t });

    await LedgerEntry.upsert(
      {
        transactionId: existing.id,
        clientId,
        asset,
        amount,
        usdValue: usdEquivalent,
        status,
        timestamp: existing.createdAt
      },
      { transaction: t }
    );
  });

  await logAudit({
    userId: req.user.id,
    action: 'UPDATE_TRANSACTION',
    entity: 'transaction',
    entityId: existing.id,
    changes: { before, after: req.body }
  });

  const result = await Transaction.findByPk(existing.id, { include: [{ model: Client, as: 'client' }] });
  return res.json(result);
}

async function getTransactions(req, res) {
  const page = Math.max(Number(req.query.page || 1), 1);
  const limit = Math.min(Math.max(Number(req.query.limit || 20), 1), 100);
  const offset = (page - 1) * limit;
  const where = buildTransactionWhere(req.query);

  const { count, rows } = await Transaction.findAndCountAll({
    where,
    include: [{ model: Client, as: 'client' }],
    order: [['createdAt', 'DESC']],
    distinct: true,
    limit,
    offset
  });

  return res.json({
    rows,
    page,
    limit,
    total: count,
    totalPages: Math.ceil(count / limit)
  });
}

module.exports = { createTransaction, updateTransaction, getTransactions };
