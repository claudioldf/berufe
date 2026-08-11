export interface Service {
  id: string
  name: string
  slug: string
  category: string
  icon: string
  description: string
  aliases: string[]
}

export interface Neighborhood {
  code: string
  name: string
}

export interface Evidence {
  id: string
  label: string
  type: 'automatic' | 'reviewed'
  date: string
}

export interface PortfolioItem {
  id: string
  title: string
  service: string
  description: string
  image: string
}

export interface Recommendation {
  id: string
  clientName: string
  service: string
  period: string
  text: string
  phoneConfirmed: boolean
}

export interface Relationship {
  id: string
  professionalName: string
  professionalSlug: string
  avatar: string
  type: 'recommendation' | 'worked_together'
  note: string
}

export interface Professional {
  id: string
  slug: string
  name: string
  headline: string
  bio: string
  avatar: string
  coverImage: string
  primaryService: string
  primaryServiceSlug: string
  services: string[]
  serviceNotes: string[]
  neighborhoods: string[]
  allJoinville: boolean
  yearsExperience: number
  evidence: Evidence[]
  portfolio: PortfolioItem[]
  recommendations: Recommendation[]
  relationships: Relationship[]
  updatedAt: string
  whatsapp: string
}

export interface QuoteItem {
  id: number
  description: string
  quantity: number
  unit: string
  unitPrice: number
}

export interface Quote {
  number: number
  customerName: string
  serviceDescription: string
  validUntil: string
  issuedAt?: string
  discount: number
  notes: string
  items: QuoteItem[]
}

export interface ToastMessage {
  title: string
  description: string
}
