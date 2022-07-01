/* 1.	Create a new database, load the attached csv file into a new table.

-- Table: public.hate_crime

-- DROP TABLE IF EXISTS public.hate_crime;

CREATE TABLE IF NOT EXISTS public.hate_crime
(
    incident_id numeric NOT NULL,
    data_year numeric,
    ori text COLLATE pg_catalog."default",
    pub_agency_name text COLLATE pg_catalog."default",
    pub_agency_unit text COLLATE pg_catalog."default",
    agency_type_name text COLLATE pg_catalog."default",
    state_abbr text COLLATE pg_catalog."default",
    state_name text COLLATE pg_catalog."default",
    division_name text COLLATE pg_catalog."default",
    region_name text COLLATE pg_catalog."default",
    population_group_code text COLLATE pg_catalog."default",
    population_group_desc text COLLATE pg_catalog."default",
    incident_date date,
    adult_victim_count numeric,
    juvenile_victim_count numeric,
    total_offender_count numeric,
    adult_offender_count numeric,
    juvenile_offender_count numeric,
    offender_race text COLLATE pg_catalog."default",
    offender_ethnicity text COLLATE pg_catalog."default",
    victim_count numeric,
    offense_name text COLLATE pg_catalog."default",
    total_individual_victims numeric,
    location_name text COLLATE pg_catalog."default",
    bias_desc text COLLATE pg_catalog."default",
    victim_types text COLLATE pg_catalog."default",
    multiple_offense text COLLATE pg_catalog."default",
    multiple_bias text COLLATE pg_catalog."default",
    CONSTRAINT hate_crime_pkey PRIMARY KEY (incident_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.hate_crime
    OWNER to postgres;
-----------------------------------------------------------------------------	
2.	Explore the dataset and provide a description of what the dataset is presenting in 
    terms of (1) time frame, (2) geographic regions, (3) kinds of crimes, (4) kind of people, (5) who were
	the reporters of the crimes in the dataset. Provide description as well as your 
	exploratory queries. (Bonus: Found other interesting info?)*/	

/* 2.1 time frame: As we can see from the query below, the dataset includes hate crimes from 1991-2020 (30 year time frame) */
select distinct data_year from hate_crime order by data_year desc; 
select incident_date from hate_crime WHERE extract(year FROM incident_date) = 2020;

/* 2.2 geographic regions: As we can see from the query below, the dataset includes numerous geographic features
		- 6 US geographic regions, like West, Midwest, Northeast, South, U.S. Territiories and Other
		- 53 states (1 query for the abbreviations and 1 for the full names
		- 11 geaographic divisions (e.g., New England, Pacific, Mountain etc.*/
select distinct region_name from hate_crime order by region_name desc;
select distinct state_abbr from hate_crime order by state_abbr desc;
select distinct state_name from hate_crime order by state_name desc;
select distinct division_name from hate_crime order by division_name desc;

/* 2.3 kinds of crimes: The dataset includes a total of 353 distinct compositions of crimes 
   that an offender has committed. This means that each row (incident), can contain more than one offenses/crimes
   which are separated by semicolons. In order to get a list of all the unique kinds of crimes, I used the 
   "unnest()" function, resulting in 48 kinds of crimes */
select distinct offense_name from hate_crime order by offense_name desc; /*353 diff compositions of offenses/crimes*/
select distinct unnest(string_to_array(offense_name, ';')) AS val from hate_crime order by val desc; /* 49 unique kinds of crimes*/

/* 2.4 kind of people: The dataset has multiple columns that describe the kinds of people
   1. There are 9 different types of victims (Individual, Law Enforcement Officer, Society/Public, Business, Government, Religious Organization, Financial Institution, Other, Unknown)
   2. There are 7 categories for the race of the offender + 1 category left blank in 20 instances (White, Unkown, Native Hawaiian, Multiple, Black or African American, Asian, American Indian
   3. There are 4 categories for the ethnicity of the offender + 1 category left blank in 184704 instances. This could go under a new 'Non Reported' category*/
select distinct unnest(string_to_array(victim_types, ';')) AS val from hate_crime order by val desc; /*55 diff combinations of victims (9 unique)*/
select distinct offender_race, count(offender_race) from hate_crime group by offender_race order by offender_race desc; /*8 diff values - 1 empty*/
select distinct offender_ethnicity, count(offender_ethnicity) from hate_crime group by offender_ethnicity order by offender_ethnicity desc;

/* 2.5 crime reporters: There are 8 kinds of reporters: University or College, Tribal, State Police, Other State Agency, Other, Federal, County, City
   Bonus: Show the crime reporter, their type of reporter and the number of instances they report a crime (sorted high-low)*/
select distinct agency_type_name, count(agency_type_name) from hate_crime group by agency_type_name order by agency_type_name desc; /*8 different types of agencies*/
select distinct pub_agency_name, agency_type_name, count(pub_agency_name) as nr_of_reports from hate_crime group by pub_agency_name, agency_type_name order by nr_of_reports desc; /*6538 agencies*/

/* ------------------------------------------------------------------------
3.	What are some of the use cases that this dataset can provide beneficial insights to the public?

    The Hate Crime Statistics dataset of the FBI Uniform Crime Reporting (UCR) Program can be beneficial in the following ways:
	1. INFORM COUNTRY-WIDE POLICY: Better understand the hate crimes as a social phenomenon in the american society. Gathering reported data
	   on any hate crime that occurs in each part of the country, helps to see the bigger picture. The dataset captures
	   reported data since 1991 and for every year we can notice the different patterns of hate crime in the US.
	2. INFORM LOCAL POLICY: We can narrow down incidents from country-wide, all the way to regions, states, cities, counties or even US Universities & Colleges
	   EXAMPLE 1: See all the crime reports for every University or College campus in the US (high to low)
	   EXAMPLE 2: See all the crime reports for every Campus in the UC system (high to low)*/
select distinct CONCAT(pub_agency_name,' ', pub_agency_unit) AS campus, count(pub_agency_name) as nr_of_reports 
from hate_crime where agency_type_name='University or College' 
group by pub_agency_name, agency_type_name, pub_agency_unit 
order by nr_of_reports desc;

select CONCAT(pub_agency_name,' ', pub_agency_unit) AS uc_campus, count(pub_agency_name) as nr_of_reports 
from hate_crime 
where pub_agency_name='University of California:' 
group by pub_agency_name, agency_type_name, pub_agency_unit 
order by nr_of_reports desc;

/*  3. ANALYZE THE NUANCES OF HATE CRIMES (both locally and federally): 
       - See the trends of hate crimes during each month of the year
	   - Which hate crime is most prevalent in a region, state, city, county in a specific time period
	   - Which states commit more racial offenses than other or which ones discriminate more against specific groups
	   - Which is the most prevalent bias per state...can we do anything to decrease those numbers through a policy intervention?
	   - Which are the top hate crime locations and inform citizens to avoid them.
	   - Which victim type is more risked from hate crimes per year or per county/location/state etc.
	4. BE CAREFUL: This dataset has a few problems:
	   - It has null values on a few columns and it's prone to errors (juvenile and adult features for both victims and offenders)
	   - It has emplty values "non-reported data", which is present on the dataset, but doesn't have values on some features, making it incomplete
	   - False Conclusions: Not all agencies have reported the data on the same way. Some have reported more than others and 
	     it doesn't show the complete picture of this social phenomenon. While California is the top state in hate-crime reports
		 it's also one of the states whose agencies have reported the most data to FBI, so it doesn't necessarily mean that
		 it's truly the state with the most crimes. Other states that have under-reported might actually have bigger problems.*/
/* ---------------------------------------------------------------------

4.	What are the bias trends in California? Are there biases that are subsiding or ones that are on the rise?
    (hint: start with counting the # of encounters of each offense per year via incident_date in California)
	
	As we saw from the above queries, the dataset contains 279 different sets of biases 
	(composed by a combination of 35 unique biases). However, since we are examining the bias trends in California
	we need to filter in the were clause by either state_abbr = 'CA' or state_name='California'. We notice that California
	from 1991-2020 has only had 59 out of the 279 sets of biases and it didn't report any case where the bias was
	categorized as "Unknown" 34 out of 35 unique biases*/ 

--select distinct bias_desc from hate_crime where state_abbr = 'CA' order by bias_desc desc; 
--select distinct unnest(string_to_array(bias_desc, ';')) AS val from hate_crime where state_abbr != 'CA' order by val desc; 

/*	METHOD 1 We count the bias frequency per year in the state of California:
	We can see that the bias trends in California, are generally increasing from year to year both in number and intensity
	Number and intensity of biases:
	In 1991: 3 biases 
	- Anti-Black or African American: 2 reported biases
	- Anti-Asian: 1 occurence
	- Anti-Jewish: 2 occurences
	In 2021: 32 different biases 
	- Anti-Black or African American: 458 reported biases
	- Anti-Asian: 90 occurence
	- Anti-Jewish: 116 occurences
	Note: A good practice would be to transpose this result with a pivot table and have columns for each year*/
	
select data_year, bias_desc, count(*) as bias_frequency
from hate_crime 
where state_abbr='CA'  
group by data_year, bias_desc 
order by data_year asc

/*	METHOD 2: Analyze the trends individually:
	- All biases for 1 year
	- All years analyzing the trends of 1 specific bias of interest*/
SELECT distinct unnest(string_to_array(bias_desc, ';')) AS val, count(incident_date) as y2020
from hate_crime
where state_abbr = 'CA' and data_year = 2020
group by val
order by y2020 desc

select data_year, count(incident_date) as anti_arab 
from hate_crime 
where state_abbr='CA' and bias_desc='Anti-Arab' 
group by data_year 
order by data_year desc

/* ---------------------------------------------------------------------
5.	How does the composition of crimes (set of committed crimes and their frequency)  differ from Juvenile victims compared to adult victims? How about Juvenile offenders vs. adult offenders?*/

/*5.1: DIFFERENCES IN VICTIMS
	5.1.1: ADULT VICTIM: were victims in 197 sets of hate crimes. Top 3 crimes involving adult victims:
  		1. Intimidation: 9090 times
  		2. Simple Assault: 6537 times
  		3. Destruction/Damage/Vandalism of Property: 4262 times */
select offense_name, count(*) as frequency_per_adult_victim
from hate_crime
where adult_victim_count > 0
group by offense_name
order by frequency_per_adult_victim desc
/*	5.1.2: JUVENILE VICTIM: were victims in 67 sets of hate crimes. Top 3 crimes, involving juvenile victims:
  		1. Intimidation: 1368 times
  		2. Simple Assault: 1048 times
  		3. Aggravated Assault: 353 times*/
select offense_name, count(*) as frequency_per_juvenile_victim
from hate_crime
where juvenile_victim_count > 0
group by offense_name
order by frequency_per_juvenile_victim desc

/*5.2: DIFFERENCES IN OFFENDERS
	5.2.1: ADULT OFFENDERS: committed 188 sets of hate crimes. Top 3 crimes committed:
  		1. Intimidation: 6083 times
  		2. Simple Assault: 5880 times
  		3. Destruction/Damage/Vandalism of Property: 3303 times */
select offense_name, count(*) as frequency_per_adult_offender
from hate_crime
where adult_offender_count > 0
group by offense_name
order by frequency_per_adult_offender desc
/*	5.1.2: JUVENILE VICTIM: committed 76 sets of hate crimes. Top 3 crimes committed:
  		1. Intimidation: 1021 times
  		2. Simple Assault: 852 times
  		3. Aggravated Assault: 546 times*/
select offense_name, count(*) as frequency_per_juvenile_offender
from hate_crime
where juvenile_offender_count > 0
group by offense_name
order by frequency_per_juvenile_offender desc

/*	BONUS: Get the frequency and number of victims per offence type all aggregated in one table*/
select offense_name, count(offense_name) as frequency, 
					 sum(COALESCE(adult_victim_count,0)) as adult_victim,
					 sum(COALESCE(juvenile_victim_count,0)) as juvenile_victim, 
					 sum(COALESCE(juvenile_offender_count,0)) as juvenile_offender, 
					 sum(COALESCE(adult_offender_count,0)) as adult_offender 
from hate_crime 
group by offense_name
order by frequency desc;
/* ---------------------------------------------------------------------
6.	What is the composition of crimes for the top 3 crime locations (in terms of victim count per location_name) in California?

	Since we are interested in the top 3 crime locations we do the following:
	- select location name and another column that adds up all the victim_counts per location
	- Filter in the where clause for california by either state_abbr = 'CA' or state_name='California'.
	- Group by location_name to get the number of victims per location
	- Order in decending order to have the top results at the top
	- Limit 3 to get just the top 3 results
	RESULTS:
	1. Residence/Home: 13901 victims
	2. Highway/Road/Alley/Street/Sidewalk: 12826 victims
	3. School/College: 3025 victims*/

select location_name, sum(victim_count) as nr_of_victims
from hate_crime 
where state_name='California'
group by location_name
order by nr_of_victims desc
limit 3;

/*	BONUS: Get the composition of the offence_type per top location*/

select distinct location_name, offense_name, count(offense_name) as freq, sum(victim_count) as victim 
from hate_crime 
where state_name='California'
group by offense_name, location_name
order by victim desc
limit 10;












