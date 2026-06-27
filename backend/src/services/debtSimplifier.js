/**
 * Simplify debts within a group.
 * Input: array of { from: userId, to: userId, amount: number }
 * Output: optimized array of settlements with minimum transactions
 */
function simplifyDebts(balances) {
  // balances: [{ userId, net: number }] where net > 0 means is owed money
  const creditors = balances.filter(b => b.net > 0).sort((a, b) => b.net - a.net);
  const debtors = balances.filter(b => b.net < 0).sort((a, b) => a.net - b.net);
  const settlements = [];

  let i = 0, j = 0;
  while (i < creditors.length && j < debtors.length) {
    const credit = creditors[i].net;
    const debt = -debtors[j].net;
    const amount = Math.min(credit, debt);

    if (amount > 0) {
      settlements.push({
        from: debtors[j].userId,
        to: creditors[i].userId,
        amount: Math.round(amount)
      });
    }

    creditors[i].net -= amount;
    debtors[j].net += amount;

    if (creditors[i].net < 1) i++;
    if (debtors[j].net > -1) j++;
  }

  return settlements;
}

module.exports = { simplifyDebts };
