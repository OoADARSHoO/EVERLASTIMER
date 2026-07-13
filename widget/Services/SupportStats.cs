using Postgrest.Attributes;
using Postgrest.Models;

namespace EverlastimerWidget.Services;

/// <summary>
/// Represents a single support statistics row from the Supabase support_stats table.
/// </summary>
[Table("support_stats")]
public sealed class SupportStats : BaseModel
{
    /// <summary>
    /// The month label for the statistics entry.
    /// </summary>
    [Column("month")]
    public string? Month { get; set; }

    /// <summary>
    /// The monthly budget value.
    /// </summary>
    [Column("budget")]
    public decimal? Budget { get; set; }

    /// <summary>
    /// The amount received for the month.
    /// </summary>
    [Column("received")]
    public decimal? Received { get; set; }

    /// <summary>
    /// Hosting-related cost for the month.
    /// </summary>
    [Column("hosting")]
    public decimal? Hosting { get; set; }

    /// <summary>
    /// Database-related cost for the month.
    /// </summary>
    [Column("database")]
    public decimal? Database { get; set; }

    /// <summary>
    /// Content delivery network-related cost for the month.
    /// </summary>
    [Column("cdn")]
    public decimal? Cdn { get; set; }

    /// <summary>
    /// API-related cost for the month.
    /// </summary>
    [Column("apis")]
    public decimal? Apis { get; set; }

    /// <summary>
    /// Any other miscellaneous cost for the month.
    /// </summary>
    [Column("other")]
    public decimal? Other { get; set; }
}
