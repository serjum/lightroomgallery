<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.application.component.modelitem');

    class LrgalleryModelPhotos extends JModelItem
    {
        /*
         * Базовый путь для папок с пользовательскими фотографиями
         */
        const folderBase = 'media/user_folders';
        
        /*
         * Текущий пользователь
         */
        protected $user; 
        
        /*
         * Фотографии пользователя
         */
        protected $photos;
        
        /*
         * Значения полей метаданных для фотографий текущего пользователя
         */
        protected $metadata;
        
        /*
         * Возвращает текущего пользователя
         */
        public function getUser()
        {
            if (!isset($this->user))
            {
                $this->user =& JFactory::getUser();
                if (!empty($this->user))
                {
                    // Добавим имя папки пользователя к объекту user
                    $db =& JFactory::getDBO();
                    $db->setQuery('SELECT folder_name
                                     FROM #__lrgallery_userfolders
                                    WHERE user_id = ' . $this->user->get('id'));
                    $this->user->folderName = $db->loadResult();
                }
            }
            
            return $this->user;
        }
        
        /*
         * Возвращает фотографии текущего пользователя
         */
        public function getPhotos()
        {
            if (!isset($this->user))
                $this->user = $this->getUser();
            
            if (!isset($this->photos))
            {
                // Выберем фотографии текущего пользователя
                $db =& JFactory::getDBO();
                $db->setQuery('SELECT * 
                                 FROM #__lrgallery_photos
                                WHERE user_id = ' . $this->user->get('id'));
                $this->photos = $db->loadObjectList();
            }
            
            for ($i = 0; $i < count($this->photos); $i++)
            {
                $this->photos[$i]->base = $this::folderBase . "/" . $this->user->folderName;
            }
            
            return $this->photos;
        }
        
        /*
         * Возвращает значения полей метаданных для фотографий текущего пользователя
         */
        public function getMetadata()
        {
            if (!isset($this->photos))
                $this->photos = $this->getPhotos();
            
            if (!isset($this->metadata))
            {
                $photoFilter = implode(',', JArrayHelper::getColumn($this->photos, 'id'));
                $db =& JFactory::getDBO();
                $db->setQuery("SELECT data.photo_id, 
                                      meta.name, 
                                      data.value
                                 FROM #__lrgallery_meta meta, 
                                      #__lrgallery_metadata data
                                WHERE meta.id = data.meta_id 
                                  AND data.photo_id IN ('$photoFilter')");
                $this->metadata = $db->loadAssocList();
            }
            
            return $this->metadata;
        }
    }
?>