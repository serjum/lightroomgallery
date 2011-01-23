<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.database.table');

    class LrgalleryTablePhoto extends JTable
    {
        function __construct(&$db) 
        {
            parent::__construct('#__lrgallery_photos', 'id', $db);
        }
    }
?>