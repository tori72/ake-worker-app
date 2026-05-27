// src/routes/items.js
// GET endpoints for all dropdown/lookup tables

const express = require('express');
const router = express.Router();
const supabase = require('../config/supabase');
const { asyncHandler } = require('../middleware/errorHandler');

/**
 * Helper — fetch all rows from a table, ordered by name/value column.
 */
async function fetchLookup(table, labelColumn = 'name') {
  const { data, error } = await supabase
    .from(table)
    .select(`id, ${labelColumn}`)
    .order(labelColumn, { ascending: true });

  if (error) {
    const err = new Error(`Supabase error fetching ${table}: ${error.message}`);
    err.status = 502;
    throw err;
  }
  return data;
}

// ─────────────────────────────────────────────
// GET /api/items/all  →  returns all dropdown data in one request
// ─────────────────────────────────────────────
router.get(
  '/all',
  asyncHandler(async (req, res) => {
    const [items, threads, lengths, heads, colours] = await Promise.all([
      fetchLookup('items', 'name'),
      fetchLookup('threads', 'name'),
      fetchLookup('lengths', 'value'),
      fetchLookup('heads', 'name'),
      fetchLookup('colours', 'name'),
    ]);

    res.json({
      success: true,
      data: { items, threads, lengths, heads, colours },
    });
  })
);

// NOTE: Individual endpoints (/names, /threads, /lengths, /heads, /colours)
// can be added here when granular fetching is needed by other screens.

module.exports = router;
