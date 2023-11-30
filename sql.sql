

ALTER TABLE `owned_vehicles`
    ADD COLUMN `infoimpound` longtext DEFAULT NULL,
    ADD COLUMN `lastparking` longtext DEFAULT NULL,
    ADD COLUMN `friends` longtext DEFAULT NULL;
    ADD COLUMN `fakeplate` varchar(12) DEFAULT NULL,
