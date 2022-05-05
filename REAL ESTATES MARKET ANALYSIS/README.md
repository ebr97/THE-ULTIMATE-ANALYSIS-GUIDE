<a href="https://pandas.pydata.org/" target="_blank" rel="noreferrer"> <img src="https://raw.githubusercontent.com/devicons/devicon/2ae2a900d2f041da66e950e4d48052658d850630/icons/pandas/pandas-original.svg" alt="pandas" width="40" height="40"/> </a> <a href="https://www.python.org" target="_blank" rel="noreferrer"> <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/python/python-original.svg" alt="python" width="40" height="40"/> </a> <a href="https://www.selenium.dev" target="_blank" rel="noreferrer"> <img src="https://raw.githubusercontent.com/detain/svg-logos/780f25886640cef088af994181646db2f6b1a3f8/svg/selenium-logo.svg" alt="selenium" width="40" height="40"/> </a>
# Real Estates Market Analysis
This is an analysis project made on real estates market near Bucharest city. 
The purpose of this was to provide an overview of the apartemnt with two rooms market. Mainly because this kind of apartemnts are targetated by the couples or young families with a small budget that are looking for new apartemnts near big cities.

## First Phase of the project - Scraping the data
For the analysis to be more accurate I choose to scrape data from <b>https://www.storia.ro/</b>. During this phase I used <b>requests</b> and <b>BeautifulSoup</b> libraries to gather all the links from the main page, here we talk about over 1000 links. Then I used 
<b>selenium</b> library, because the webpages were dynamically loaded and I need to render them before parseing them to <b>BeautifulSoup</b> library to go thru each one of the links and gather all the necessary data. </br>
The problem that occured during this phase was the fact that I wasn't been able to scrape all the 1000+ links at once, becuase the variables that stored the data got bigger and bigger and, after the first 27 links the code interrupts and throw a memory error. So the solution that I came up was to scrape thru 5 links at a time then store the information into a .csv file, then reinitialise the python variables :). All the .csv file were stored in CSV folder. 

## Second Phase of the project - Cleaning raw data
After data was scraped and stored in different .csv files now we will load it into a data frame and we will transform and clean it to prepare it for the analysis process.<br>
Some difficulties that I encounter:<br>
- the details column need it to be spplitted in aditional columns to perform an analysis
- data surounded by the extra '' and different types of characters (e.g. ].)
- the details column don't have the same categories data for each apartment
- getting the year as accuarate as posiible

## Third Phase of the project - Analyzing facts
Providing an overview about real estates market near Bucharest city with focus on the price, year of the building and the distribution of the flats along floors.
