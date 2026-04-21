const ExcelJS = require('exceljs');
const { Op } = require('sequelize');
const { Transaction, Client } = require('../models');
const { logAudit } = require('../services/auditService');

async function exportTransactionsExcel(req, res) {
  const { startDate, endDate, clientId, asset } = req.query;
  const where = {};
  if (clientId) where.clientId = clientId;
  if (asset) where.asset = asset;
  if (startDate || endDate) {
    where.createdAt = {};
    if (startDate) where.createdAt[Op.gte] = new Date(startDate);
    if (endDate) where.createdAt[Op.lte] = new Date(endDate);
  }

  const rows = await Transaction.findAll({
    where,
    include: [{ model: Client, as: 'client' }],
    order: [['createdAt', 'ASC']]
  });

  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet('Transactions');
  const summary = workbook.addWorksheet('Summary');

  sheet.columns = [
    { header: 'Transaction ID', key: 'id', width: 14 },
    { header: 'Client', key: 'client', width: 22 },
    { header: 'Asset', key: 'asset', width: 12 },
    { header: 'Amount', key: 'amount', width: 14 },
    { header: 'USD Equivalent', key: 'usd', width: 16 },
    { header: 'Type', key: 'type', width: 14 },
    { header: 'Status', key: 'status', width: 14 },
    { header: 'Timestamp', key: 'timestamp', width: 22 }
  ];

  let totalAmount = 0;
  let totalUsd = 0;
  rows.forEach((tx) => {
    const amount = Number(tx.amount);
    const usd = Number(tx.usdEquivalent);
    totalAmount += amount;
    totalUsd += usd;

    sheet.addRow({
      id: tx.id,
      client: tx.client?.name || '-',
      asset: tx.asset,
      amount,
      usd,
      type: tx.type,
      status: tx.status,
      timestamp: tx.createdAt.toISOString()
    });
  });

  const totals = sheet.addRow({
    client: 'TOTAL',
    amount: totalAmount,
    usd: totalUsd
  });
  totals.font = { bold: true };

  summary.addRows([
    ['Metric', 'Value'],
    ['Total Transactions', rows.length],
    ['Total Amount', totalAmount],
    ['Total USD Equivalent', totalUsd],
    ['Filters', JSON.stringify({ startDate, endDate, clientId, asset })]
  ]);
  summary.getRow(1).font = { bold: true };

  await logAudit({
    userId: req.user.id,
    action: 'EXPORT_TRANSACTIONS',
    entity: 'report',
    entityId: null,
    changes: { filters: req.query, rowCount: rows.length }
  });

  res.setHeader(
    'Content-Disposition',
    `attachment; filename=transactions_${new Date().toISOString().split('T')[0]}.xlsx`
  );
  res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  await workbook.xlsx.write(res);
  res.end();
}

module.exports = { exportTransactionsExcel };
