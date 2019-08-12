-- MySQL dump 10.14  Distrib 5.5.60-MariaDB, for Linux (x86_64)
--
-- Host: localhost    Database: weather_infos
-- ------------------------------------------------------
-- Server version	5.5.60-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `weather_infos`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `weather_infos` /*!40100 DEFAULT CHARACTER SET latin1 */;

USE `weather_infos`;

--
-- Table structure for table `citycode_infos`
--

DROP TABLE IF EXISTS `citycode_infos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `citycode_infos` (
  `weather_code` int(9) NOT NULL,
  `province` varchar(30) NOT NULL,
  `province_pinyin` varchar(30) NOT NULL,
  `province_code` varchar(30) NOT NULL,
  `province_id` varchar(10) DEFAULT NULL,
  `city` varchar(30) NOT NULL,
  `city_pinyin` varchar(30) NOT NULL,
  `city_code` varchar(30) NOT NULL,
  `city_id` varchar(10) DEFAULT NULL,
  `county` varchar(30) NOT NULL,
  `county_pinyin` varchar(30) NOT NULL,
  `county_code` varchar(30) NOT NULL,
  `county_id` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`weather_code`),
  KEY `province` (`province`,`city`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `district`
--

DROP TABLE IF EXISTS `district`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `district` (
  `id` smallint(5) DEFAULT NULL,
  `name` varchar(270) DEFAULT NULL,
  `parent_id` smallint(5) DEFAULT NULL,
  `pinyin` varchar(600) DEFAULT NULL,
  `initial` char(3) DEFAULT NULL,
  `initials` varchar(30) DEFAULT NULL,
  `suffix` varchar(15) DEFAULT NULL,
  `code` char(30) DEFAULT NULL,
  `order` tinyint(2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lng_lat_location`
--

DROP TABLE IF EXISTS `lng_lat_location`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lng_lat_location` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `lng_lat` varchar(12) NOT NULL,
  `weather_code` int(12) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `lng_lat` (`lng_lat`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `weather_records`
--

DROP TABLE IF EXISTS `weather_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `weather_records` (
  `citycode` int(9) NOT NULL,
  `date` date NOT NULL,
  `cityname` varchar(50) NOT NULL,
  `date_txt` varchar(12) DEFAULT NULL,
  `weather` varchar(50) DEFAULT NULL,
  `temperature` varchar(50) DEFAULT NULL,
  `wind_scale` varchar(30) DEFAULT NULL,
  `description` text,
  `weather_ico` varchar(10) DEFAULT NULL,
  `c_temperature` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`citycode`,`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2019-08-02 18:23:35
