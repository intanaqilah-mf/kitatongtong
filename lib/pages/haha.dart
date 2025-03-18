Center(
child: Text(
"Auto-generated voucher redemption:\n"
"${minRedeemablePoints} pts → RM1\n"
"${(minRedeemablePoints * multiplier).round()} pts → RM2\n"
"${(minRedeemablePoints * multiplier * multiplier).round()} pts → RM4\n"
"${(minRedeemablePoints * multiplier * multiplier * multiplier).round()} pts → RM8\n",
style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70),
textAlign: TextAlign.center, // ✅ Ensures text alignment is centered
),
),