<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.application.component.modellist');

    class LrgalleryModelPhotos extends JModelList
    {
        protected function getListQuery()
        {
            $db = JFactory::getDBO();
            $query = $db->getQuery(true);
            $query->select('p.id, u.name as user_name, p.file_name');
            $query->from('#__lrgallery_photos p, #__users u');
            $query->where('p.user_id = u.id');
            
            return $query;
        }
    }
?>