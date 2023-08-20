********************************************************************************

/* Regression: omitted variables and bad controls */

clear all
set more off
set seed 10000


//-- generate correlated independent variables --// 
matrix C=(1,0.5 \ 0.5, 1)
matrix M=(0,0)
matrix S=(1,1)
corr2data x3 x4, n(10000) means(M) sds(S) corr(C) seed(1) clear 


//-- generate uncorrelated independent variables --// 
gen x1 = rnormal()
gen x2 = rnormal()

gen e1 = rnormal()
gen e2 = rnormal()


//-- generate dependent variables --// 
gen y1 = 2*x1+3*x2+e1
gen y2 = 2*x3+3*x4+e2

sum x1 x2 x3 x4
corr x1 x2 x3 x4


//-- zero conditional error --// 
eststo clear
eststo: qui reg y1 x1 x2,r
eststo: qui reg y1 x1,r
eststo: qui reg y1 x2,r 
esttab, b(3) nostar nogap bracket ar2


//-- zero conditional error VIOLATED! --// 
eststo clear
eststo: qui reg y2 x3 x4,r
eststo: qui reg y2 x4,r
eststo: qui reg y2 x3,r 
esttab, b(3) nostar nogap bracket ar2


//-- bad controls --// 
gen x5 = 2*x3 + 3*e2 + rnormal()

eststo clear
eststo: reg y2 x3 x4,r
eststo: reg y2 x1 x2 x3 x4,r
eststo: reg y2 x3 x4 x5,r 
esttab, b(3) nostar nogap bracket ar2

reg y2 x3 x4,r
test x3=0 // same test using F-stat
test x3 // same test
test x3 x4 // joint test of x3 = 0 & x4 = 0
test x3-x4=0
test (x3=2) (x4=2)

********************************************************************************
*
*
*
********************************************************************************

/* Times Series */

clear
set obs 10000

set seed 1
gen e1 = rnormal() // white noise 
gen ee = rnormal()

gen t = _n
tsset t

gen e2 = .
replace e2 = 0 in 1
forvalues i = 2/10000{
	qui replace e2 = 0.9*l.e2 + ee in `i'
} // AR(1)=0.9

gen e3 = .
replace e3 = 0 in 1
forvalues i = 2/10000{
	qui replace e3 = 0.5*l.e3 + ee in `i'
} // AR(1)=0.5

forvalues i = 1/3{
	reg e`i' l.e`i'
}
sum e1 e2 e3,d


twoway line e1 e2 e3 t, lcolor(red blue black) yscale(range(-10 10)) ylabel(-10(5)10)  graphregion(color(white))
twoway line e1 t, lcolor(red) yscale(range(-10 10)) ylabel(-10(5)10) graphregion(color(white))
twoway line e2 t if t<100, lcolor(blue) yscale(range(-10 10)) ylabel(-10(5)10)  graphregion(color(white))
twoway line e3 t, lcolor(black) yscale(range(-10 10)) ylabel(-10(5)10)  graphregion(color(white))



*******************************************************************************
*
*
*
*******************************************************************************

/* Unit Root: simulation of random walk */

clear
set obs 1000
gen t =.
save "D:\Dropbox\Teaching\2022Spring Financial Econometrics\program\unit_t.dta",replace

forvalues x =1/1000{
	clear
	set seed `x'
	set obs 1000
	gen t = _n
	sort t
	tsset t

	gen e = rnormal()
	gen y = .
	replace y = 0 in 1
	forvalues i = 2/1000{
		qui replace y = l.y + e in `i'
	}
	qui reg y l.y
	di (_b[l.y]-1)/_se[l.y]
	local trial (_b[l.y]-1)/_se[l.y]
	use "D:\Dropbox\Teaching\2022Spring Financial Econometrics\program\unit_t.dta", clear
	replace t = `trial' in `x'
	save "D:\Dropbox\Teaching\2022Spring Financial Econometrics\program\unit_t.dta", replace
}
use "D:\Dropbox\Teaching\2022Spring Financial Econometrics\program\unit_t.dta",clear
hist t, freq bin(50) graphregion(color(white)) fcolor(blue%30) lcolor(navy%50) xline(0, lc(red)) text(80 -1.8 "mean: -1.54") text(76.5 -1.8 "median: -1.57") title("Distribution of {it:t}-statistics for H{subscript:0}:ρ=1")


*******************************************************************************
*
*
*
*******************************************************************************

/*Unit Root: Spurious Regression*/

clear
set obs 1000
gen r2 =.
gen p =.
save "D:\Dropbox\Teaching\2022Spring Financial Econometrics\program\spur.dta",replace

forvalues x =1/1000{
	set seed `x'
	set obs 1000
	gen t = _n
	sort t
	tsset t

	gen e1 = rnormal()
	gen e2 = rnormal()
	gen y = .
	gen x = .
	replace y = 0 in 1
	replace x = 0 in 1
	forvalues i = 2/1000{
		qui replace y = l.y + e1 in `i'
		qui replace x = l.x + e2 in `i'		
	}
	qui reg y x,r
	local r2 e(r2)
	local p 2*normal(-abs(_b[x]/_se[x])) 	
	use "D:\Dropbox\Teaching\2022Spring Financial Econometrics\program\spur.dta", clear
	replace p = `p' in `x'
	replace r2 = `r2' in `x'
	save "D:\Dropbox\Teaching\2022Spring Financial Econometrics\program\spur.dta", replace	
}
use "D:\Dropbox\Teaching\2022Spring Financial Econometrics\program\spur.dta", clear
hist p, freq bin(20) graphregion(color(white)) fcolor(blue%30) lcolor(navy%50) xline(0.05, lc(red)) text(800 0.35 "940 out of 1,000 simulated {it:p}-value < 0.05") title("Distribution of {it:p}-value of Spurious Regressions")
hist r2, freq bin(50) graphregion(color(white)) fcolor(blue%30) lcolor(navy%50) text(100 0.1 "mean:0.24")  text(90 0.11 "median:0.18") title("Distribution of {it:R}{superscript:2} of Spurious Regressions")



*******************************************************************************
*
*
*
*******************************************************************************
/* Dickey Fuller Test */

clear
set obs 1000
set seed 12345
gen t = _n
sort t
tsset t

gen e1 = rnormal()
gen e2 = rnormal()
gen y = .
gen x = .
replace y = 0 in 1
replace x = 0 in 1
forvalues i = 2/1000{
	qui replace y = l.y + e1 in `i'
	qui replace x = 0.8*l.x + e2 in `i'		
}

dfuller y 
reg d.y l.y


dfuller y, trend
reg d.y l.y t


dfuller x 
dfuller x, trend

dfuller y, trend lags(5)
dfuller x, trend lags(5)

dfuller d.y 
dfuller d.y,trend 

// AR(2) with unit root
gen z =.
replace z = 0 in 1/2
forvalues i = 3/1000{
	qui replace z = 0.5*l.z + 0.5*l2.z + e1 in `i'
}

reg z l.z
estat ic
reg z l.z l2.z
estat ic 
reg z l.z l2.z l3.z
estat ic

dfuller z
dfuller z,lag(2)
dfuller d.z
dfuller d.z,lag(2)

*******************************************************************************

