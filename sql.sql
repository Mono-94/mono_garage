


---- ESX DEFAULT
-- 
-- Table structure for table `owned_vehicles`
--

CREATE TABLE `owned_vehicles` (
  `owner` varchar(60) DEFAULT NULL,
  `plate` varchar(12) NOT NULL,
  `vehicle` longtext DEFAULT NULL,
  `type` varchar(20) NOT NULL DEFAULT 'car',
  `job` varchar(20) DEFAULT NULL,
  `stored` tinyint(4) NOT NULL DEFAULT 0,
  `parking` VARCHAR(60) DEFAULT NULL,
  `pound` VARCHAR(60) DEFAULT NULL
) ENGINE=InnoDB;


-- mono garage
ALTER TABLE `owned_vehicles`
    ADD COLUMN `infoimpound` longtext DEFAULT NULL,
    ADD COLUMN `lastparking` longtext DEFAULT NULL,
    ADD COLUMN `friends` longtext DEFAULT NULL;
    ADD COLUMN `fakeplate` varchar(12) DEFAULT NULL,
