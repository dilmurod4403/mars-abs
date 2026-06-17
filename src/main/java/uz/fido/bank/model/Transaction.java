package uz.fido.bank.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class Transaction {
    private long txnId;
    private Long fromAccount;
    private Long toAccount;
    private String txnType;
    private BigDecimal amount;
    private String currency;
    private String description;
    private LocalDateTime txnDate;
    private String status;

    private String fromAccountNum;
    private String toAccountNum;

    public long getTxnId() { return txnId; }
    public void setTxnId(long txnId) { this.txnId = txnId; }

    public Long getFromAccount() { return fromAccount; }
    public void setFromAccount(Long fromAccount) { this.fromAccount = fromAccount; }

    public Long getToAccount() { return toAccount; }
    public void setToAccount(Long toAccount) { this.toAccount = toAccount; }

    public String getTxnType() { return txnType; }
    public void setTxnType(String txnType) { this.txnType = txnType; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public LocalDateTime getTxnDate() { return txnDate; }
    public void setTxnDate(LocalDateTime txnDate) { this.txnDate = txnDate; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getFromAccountNum() { return fromAccountNum; }
    public void setFromAccountNum(String fromAccountNum) { this.fromAccountNum = fromAccountNum; }

    public String getToAccountNum() { return toAccountNum; }
    public void setToAccountNum(String toAccountNum) { this.toAccountNum = toAccountNum; }
}
