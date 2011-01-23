<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.application.component.modellist');

    class LrgalleryModelUserfolders extends JModelList
    {
        protected function getListQuery()
        {
            $db = JFactory::getDBO();
            $query = $db->getQuery(true);
            $query->select('f.id, u.name as user_name, f.folder_name');
            $query->from('#__lrgallery_userfolders f, #__users u');
            $query->where('f.user_id = u.id');
            
            return $query;
        }
    }
?>