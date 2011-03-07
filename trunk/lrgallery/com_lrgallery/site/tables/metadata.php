<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.database.table');

    class LrgalleryTableMetadata extends JTable
    {
        function __construct(&$db) 
        {
            parent::__construct('#__lrgallery_metadata', 'photo_id, meta_id', $db);
        }
    }
?>