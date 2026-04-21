const { sequelize, Transaction, Client } = require('../models');

async function getDashboard(req, res) {
  const [txCount, clientBalanceRows, revenueRows, recentTransactions] = await Promise.all([
    Transaction.count(),
    Transaction.findAll({
      attributes: [
        [
          sequelize.literal(`SUM(CASE
            WHEN type = 'deposit' AND status = 'completed' THEN "usdEquivalent"
            WHEN type = 'trade' AND status = 'completed' THEN "usdEquivalent"
            WHEN type = 'withdrawal' AND status = 'completed' THEN -"usdEquivalent"
            WHEN type = 'fee' AND status = 'completed' THEN -"usdEquivalent"
            ELSE 0 END)`),
          'totalBalance'
        ]
      ],
      raw: true
    }),
    Transaction.findAll({
      attributes: [[sequelize.fn('SUM', sequelize.col('usdEquivalent')), 'totalRevenue']],
      where: { type: 'fee', status: 'completed' },
      raw: true
    }),
    Transaction.findAll({
      include: [{ model: Client, as: 'client' }],
      order: [['createdAt', 'DESC']],
      limit: 10
    })
  ]);

  return res.json({
    totalTransactions: txCount,
    totalClientBalances: Number(clientBalanceRows[0].totalBalance || 0),
    totalRevenue: Number(revenueRows[0].totalRevenue || 0),
    recentTransactions
  });
}

module.exports = { getDashboard };
