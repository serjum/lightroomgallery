<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.database.table');

    class LrgalleryTableUserfolder extends JTable
    {
        function __construct(&$db) 
        {
            parent::__construct('#__lrgallery_userfolders', 'id', $db);
        }
    }
?>