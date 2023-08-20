
/* Market Return and Volatility Clustering */

// read data
import excel "D:\Dropbox\Teaching\2022Spring Financial Econometrics\program\SPY.xlsx", sheet("SPY") firstrow clear
// define time variable
format Date %td
sort Date
gen t=_n
tsset t

// calculate return and log return
gen ret = (AdjClose-l.AdjClose)/AdjClose
gen lnret = ln(ret+1)

// generate month variable
gen month = mofd(Date)
format month %tm

// calculate monthly return and return standard deviation
collapse (sum) lnret (sd) ret, by(month)
rename ret retsd
gen ret = exp(lnret)-1

tsset, clear
tsset month

// time-series plotting of return and std
twoway line ret month, graphregion(color(white)) ytitle("SPY Return Time Series") xtitle("")
twoway line retsd month, graphregion(color(white)) ytitle("SPY Ret Std. Time Series") xtitle("")

// plotting of return and std ACF coefficients
ac ret, lags(10) graphregion(color(white)) mcolor(blue) msymbol(s) lcolor(blue) ciopts(color(gs12%50)) yline(0,lc(red)) ytitle("ACF coefficients of SPY Return")

ac retsd, lags(10) graphregion(color(white)) mcolor(blue) msymbol(s) lcolor(blue) ciopts(color(gs12%50)) yline(0,lc(red)) ytitle("ACF coefficients of SPY Ret Std.")

// monthly autoregression of return and std
reg retsd l.retsd
reg ret l.ret

// newey-west to adjust for serial correlation
newey retsd l.retsd, lag(12)
newey ret l.ret, lag(12)

// box-pierce test
wntestq ret, lags(12)
wntestq retsd, lags(12)

/* test of ARCH */
// establish some model: say AR(1) for return
reg ret l.ret
predict resi,r

gen vol=resi^2
reg vol l.vol,r 
newey vol l.vol,lag(12)

ac vol, lags(10) graphregion(color(white)) mcolor(blue) msymbol(s) lcolor(blue) ciopts(color(gs12%50)) yline(0,lc(red))

// model 2: AR(2)
reg ret l.ret l2.ret
predict resi2,r

gen vol2=resi2^2
reg vol2 l.vol2,r 
newey vol2 l.vol2,lag(12)

// plotting together
corr retsd vol vol2
twoway line retsd vol month, lcolor(red%70 blue%70) graphregion(color(white))

