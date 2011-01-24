<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.database.table');

    class LrgalleryTableMeta extends JTable
    {
        function __construct(&$db) 
        {
            parent::__construct('#__lrgallery_meta', 'id', $db);
        }
    }
?>