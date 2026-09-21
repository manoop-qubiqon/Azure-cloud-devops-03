package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/trainwithshubham/skillpulse/database"
	"github.com/trainwithshubham/skillpulse/models"
)

func GetSkills(c *gin.Context) {
	rows, err := database.DB.Query(`
		SELECT s.id, s.name, s.category, s.target_hours,
		       COALESCE(SUM(l.hours), 0) as total_hours, s.created_at
		FROM skills s
		LEFT JOIN learning_logs l ON s.id = l.skill_id
		GROUP BY s.id, s.name, s.category, s.target_hours, s.created_at
		ORDER BY s.created_at DESC
	`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	skills := []models.Skill{}
	for rows.Next() {
		var s models.Skill
		if err := rows.Scan(&s.ID, &s.Name, &s.Category, &s.TargetHours, &s.TotalHours, &s.CreatedAt); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		skills = append(skills, s)
	}

	c.JSON(http.StatusOK, skills)
}

func CreateSkill(c *gin.Context) {
	var req models.CreateSkillRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	result, err := database.DB.Exec(
		"INSERT INTO skills (name, category, target_hours) VALUES (?, ?, ?)",
		req.Name, req.Category, req.TargetHours,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	id, _ := result.LastInsertId()
	c.JSON(http.StatusCreated, gin.H{"id": id, "message": "Skill created"})
}

func GetSkill(c *gin.Context) {
	id := c.Param("id")

	var skill models.Skill
	err := database.DB.QueryRow(`
		SELECT s.id, s.name, s.category, s.target_hours,
		       COALESCE(SUM(l.hours), 0) as total_hours, s.created_at
		FROM skills s
		LEFT JOIN learning_logs l ON s.id = l.skill_id
		WHERE s.id = ?
		GROUP BY s.id, s.name, s.category, s.target_hours, s.created_at
	`, id).Scan(&skill.ID, &skill.Name, &skill.Category, &skill.TargetHours, &skill.TotalHours, &skill.CreatedAt)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Skill not found"})
		return
	}

	// Get learning logs for this skill
	rows, err := database.DB.Query(
		"SELECT id, skill_id, hours, notes, log_date, created_at FROM learning_logs WHERE skill_id = ? ORDER BY log_date DESC",
		id,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	logs := []models.LearningLog{}
	for rows.Next() {
		var l models.LearningLog
		if err := rows.Scan(&l.ID, &l.SkillID, &l.Hours, &l.Notes, &l.LogDate, &l.CreatedAt); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		logs = append(logs, l)
	}

	c.JSON(http.StatusOK, gin.H{"skill": skill, "logs": logs})
}

func DeleteSkill(c *gin.Context) {
	id := c.Param("id")

	result, err := database.DB.Exec("DELETE FROM skills WHERE id = ?", id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Skill not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Skill deleted"})
}
