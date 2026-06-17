package uz.fido.abs.core.model;

import java.io.Serializable;
import java.util.*;

/**
 * Filter ta'rifi — qaysi ustun bo'yicha filter qilinadi.
 */
public class FilterDef implements Serializable {
    private String field;       // DB column name
    private String label;       // Display label
    private String type;        // "text", "select", "date"
    private String value;       // Current filter value (from request)
    private List<String[]> options;  // For select: [value, label] pairs

    // Default constructor
    public FilterDef() { this.type = "text"; }

    public FilterDef(String field, String label, String type) {
        this.field = field;
        this.label = label;
        this.type = type != null ? type : "text";
    }

    // All getters and setters
    public String getField() { return field; }
    public void setField(String field) { this.field = field; }
    public String getLabel() { return label; }
    public void setLabel(String label) { this.label = label; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public String getValue() { return value; }
    public void setValue(String value) { this.value = value; }
    public List<String[]> getOptions() { return options; }
    public void setOptions(List<String[]> options) { this.options = options; }

    /**
     * Parse options string: "ACTIVE,PENDING,BLOCKED" or "ACTIVE:Faol,PENDING:Kutilmoqda"
     */
    public void parseOptions(String optStr) {
        if (optStr == null || optStr.isEmpty()) return;
        options = new ArrayList<>();
        for (String opt : optStr.split(",")) {
            opt = opt.trim();
            if (opt.contains(":")) {
                String[] parts = opt.split(":", 2);
                options.add(new String[]{parts[0], parts[1]});
            } else {
                options.add(new String[]{opt, opt});
            }
        }
    }
}
