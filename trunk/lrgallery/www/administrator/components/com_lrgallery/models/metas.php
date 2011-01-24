<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.application.component.modellist');

    class LrgalleryModelMetas extends JModelList
    {
        protected function getListQuery()
        {
            $db = JFactory::getDBO();
            $query = $db->getQuery(true);
            $query->select('m.id, m.name, m.desc');
            $query->from('#__lrgallery_meta m');
            
            return $query;
        }
    }
?>