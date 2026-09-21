package models

import "time"

type Skill struct {
	ID          int       `json:"id"`
	Name        string    `json:"name"`
	Category    string    `json:"category"`
	TargetHours int       `json:"target_hours"`
	TotalHours  float64   `json:"total_hours"`
	CreatedAt   time.Time `json:"created_at"`
}

type CreateSkillRequest struct {
	Name        string `json:"name" binding:"required"`
	Category    string `json:"category"`
	TargetHours int    `json:"target_hours"`
}

type LearningLog struct {
	ID        int       `json:"id"`
	SkillID   int       `json:"skill_id"`
	Hours     float64   `json:"hours"`
	Notes     string    `json:"notes"`
	LogDate   string    `json:"log_date"`
	CreatedAt time.Time `json:"created_at"`
}

type CreateLogRequest struct {
	Hours   float64 `json:"hours" binding:"required"`
	Notes   string  `json:"notes"`
	LogDate string  `json:"log_date" binding:"required"`
}

type Dashboard struct {
	TotalSkills int     `json:"total_skills"`
	TotalHours  float64 `json:"total_hours"`
	TotalLogs   int     `json:"total_logs"`
	TopSkill    string  `json:"top_skill"`
}
